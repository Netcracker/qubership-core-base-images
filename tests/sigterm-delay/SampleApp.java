public class SampleApp {
    public static void main(String[] args) throws Exception {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("Java app: captured SIGTERM");
        }));
        System.out.println("Java app: started");
        Thread.sleep(5000);
        System.out.println("Java app: delayed message");
        while (true) {
            Thread.sleep(1000);
        }
    }
}
