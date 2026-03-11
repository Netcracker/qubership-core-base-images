// This application gathers OTEL metrics (and traces/logs) and outputs them to the console.
// It is used as the target for OTEL metrics from the nginx server in tests.
package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	collogpb "go.opentelemetry.io/proto/otlp/collector/logs/v1"
	colmetricpb "go.opentelemetry.io/proto/otlp/collector/metrics/v1"
	coltracepb "go.opentelemetry.io/proto/otlp/collector/trace/v1"
	metricpb "go.opentelemetry.io/proto/otlp/metrics/v1"
	"google.golang.org/grpc"
)

type metricsServer struct {
	colmetricpb.UnimplementedMetricsServiceServer
}

func (s *metricsServer) Export(_ context.Context, req *colmetricpb.ExportMetricsServiceRequest) (*colmetricpb.ExportMetricsServiceResponse, error) {
	for _, rm := range req.GetResourceMetrics() {
		res := rm.GetResource()
		log.Printf("[metrics] resource: %d attribute(s)", len(res.GetAttributes()))
		for _, attr := range res.GetAttributes() {
			log.Printf("[metrics]   %s = %v", attr.GetKey(), attr.GetValue())
		}
		for _, sm := range rm.GetScopeMetrics() {
			log.Printf("[metrics]   scope: %s %s", sm.GetScope().GetName(), sm.GetScope().GetVersion())
			for _, m := range sm.GetMetrics() {
				log.Printf("[metrics]     name=%q unit=%q", m.GetName(), m.GetUnit())
				logMetricData(m)
			}
		}
	}
	return &colmetricpb.ExportMetricsServiceResponse{}, nil
}

func logMetricData(m *metricpb.Metric) {
	switch d := m.GetData().(type) {
	case *metricpb.Metric_Gauge:
		for _, dp := range d.Gauge.GetDataPoints() {
			log.Printf("[metrics]       gauge %s", dpValueStr(dp))
		}
	case *metricpb.Metric_Sum:
		log.Printf("[metrics]       sum monotonic=%t temporality=%v", d.Sum.GetIsMonotonic(), d.Sum.GetAggregationTemporality())
		for _, dp := range d.Sum.GetDataPoints() {
			log.Printf("[metrics]       sum %s", dpValueStr(dp))
		}
	case *metricpb.Metric_Histogram:
		for _, dp := range d.Histogram.GetDataPoints() {
			log.Printf("[metrics]       histogram count=%d sum=%v bounds=%v", dp.GetCount(), dp.GetSum(), dp.GetExplicitBounds())
		}
	case *metricpb.Metric_Summary:
		for _, dp := range d.Summary.GetDataPoints() {
			log.Printf("[metrics]       summary count=%d sum=%v", dp.GetCount(), dp.GetSum())
		}
	case *metricpb.Metric_ExponentialHistogram:
		for _, dp := range d.ExponentialHistogram.GetDataPoints() {
			log.Printf("[metrics]       exp_histogram count=%d sum=%v scale=%d", dp.GetCount(), dp.GetSum(), dp.GetScale())
		}
	}
}

func dpValueStr(dp *metricpb.NumberDataPoint) string {
	switch v := dp.GetValue().(type) {
	case *metricpb.NumberDataPoint_AsDouble:
		return fmt.Sprintf("double=%f", v.AsDouble)
	case *metricpb.NumberDataPoint_AsInt:
		return fmt.Sprintf("int=%d", v.AsInt)
	default:
		return "?"
	}
}

type traceServer struct {
	coltracepb.UnimplementedTraceServiceServer
}

func (s *traceServer) Export(_ context.Context, req *coltracepb.ExportTraceServiceRequest) (*coltracepb.ExportTraceServiceResponse, error) {
	for _, rs := range req.GetResourceSpans() {
		res := rs.GetResource()
		log.Printf("[traces] resource: %d attribute(s)", len(res.GetAttributes()))
		for _, attr := range res.GetAttributes() {
			log.Printf("[traces]   %s = %v", attr.GetKey(), attr.GetValue())
		}
		for _, ss := range rs.GetScopeSpans() {
			log.Printf("[traces]   scope: %s %s", ss.GetScope().GetName(), ss.GetScope().GetVersion())
			for _, span := range ss.GetSpans() {
				log.Printf("[traces]     span name=%q kind=%v status=%v", span.GetName(), span.GetKind(), span.GetStatus().GetCode())
				for _, attr := range span.GetAttributes() {
					log.Printf("[traces]       %s = %v", attr.GetKey(), attr.GetValue())
				}
			}
		}
	}
	return &coltracepb.ExportTraceServiceResponse{}, nil
}

type logsServer struct {
	collogpb.UnimplementedLogsServiceServer
}

func (s *logsServer) Export(_ context.Context, req *collogpb.ExportLogsServiceRequest) (*collogpb.ExportLogsServiceResponse, error) {
	for _, rl := range req.GetResourceLogs() {
		res := rl.GetResource()
		log.Printf("[logs] resource: %d attribute(s)", len(res.GetAttributes()))
		for _, sl := range rl.GetScopeLogs() {
			log.Printf("[logs]   scope: %s", sl.GetScope().GetName())
			for _, lr := range sl.GetLogRecords() {
				log.Printf("[logs]     severity=%v body=%v", lr.GetSeverityText(), lr.GetBody())
			}
		}
	}
	return &collogpb.ExportLogsServiceResponse{}, nil
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "4317"
	}

	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("failed to listen on :%s: %v", port, err)
	}

	srv := grpc.NewServer()
	colmetricpb.RegisterMetricsServiceServer(srv, &metricsServer{})
	coltracepb.RegisterTraceServiceServer(srv, &traceServer{})
	collogpb.RegisterLogsServiceServer(srv, &logsServer{})

	go func() {
		sigCh := make(chan os.Signal, 1)
		signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
		<-sigCh
		log.Println("shutting down...")
		srv.GracefulStop()
	}()

	log.Printf("stub OTLP collector listening on :%s (traces, metrics, logs)", port)
	if err := srv.Serve(lis); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
