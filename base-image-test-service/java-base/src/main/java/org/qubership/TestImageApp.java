package org.qubership;

import java.io.*;
import java.lang.management.ManagementFactory;
import java.security.KeyStore;
import java.security.cert.X509Certificate;
import java.util.Enumeration;

import com.sun.management.HotSpotDiagnosticMXBean;

import javax.management.MBeanServer;

public class TestImageApp {

    public static void main(String[] args) throws Exception {
        if (args.length == 0) {
            System.out.println("Usage: java -jar app.jar [--version | --list-certs | --start-profiler | --dump]");
            System.exit(1);
        }

        String cmd = args[0];

        switch (cmd) {
            case "--version":
                printVersion();
                break;
            case "--list-certs":
                listCertificates();
                break;
            case "--check-profiler":
                checkProfiler();
                break;
            case "--nc-diag":
                createHeapDump();
                break;
            default:
                System.out.println("Unknown command");
        }
    }

    private static void printVersion() {
        System.out.println("Java version: " + System.getProperty("java.version"));
        System.out.println("Java vendor: " + System.getProperty("java.vendor"));
    }

    private static void listCertificates() {
        try {
            String keystorePath = System.getProperty("java.home") + "/lib/security/cacerts";
            String keystorePassword = "changeit";

            KeyStore ks = KeyStore.getInstance(KeyStore.getDefaultType());
            try (InputStream is = new FileInputStream(keystorePath)) {
                ks.load(is, keystorePassword.toCharArray());
            }

            Enumeration<String> aliases = ks.aliases();
            while (aliases.hasMoreElements()) {
                String alias = aliases.nextElement();
                X509Certificate cert = (X509Certificate) ks.getCertificate(alias);
                System.out.println("Alias: " + alias);
                System.out.println("Subject: " + cert.getSubjectDN());
                System.out.println("Issuer: " + cert.getIssuerDN());
                System.out.println("Serial Number: " + cert.getSerialNumber());
                System.out.println("Valid from: " + cert.getNotBefore() + " to " + cert.getNotAfter());
                System.out.println("------------------------------------------------------");
            }
        } catch (Exception e) {
            System.err.println("Error listing certificates: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void checkProfiler() throws Exception {
        System.out.println("waiting for app for testing");
    }

    private static void createHeapDump() throws Exception {
        System.out.println("waiting for app for testing");
    }
}