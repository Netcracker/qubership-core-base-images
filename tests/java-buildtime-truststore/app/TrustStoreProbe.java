import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;
import java.security.KeyStore;

// Initializes the default trust manager the same way frameworks do during their own build step
// (Quarkus augmentation, Keycloak's `kc.sh build`): PKIX with a null KeyStore, which makes the JDK
// read whatever trust store the image ships.
public class TrustStoreProbe {
    public static void main(String[] args) throws Exception {
        TrustManagerFactory factory = TrustManagerFactory.getInstance("PKIX");
        factory.init((KeyStore) null);

        X509TrustManager trustManager = (X509TrustManager) factory.getTrustManagers()[0];
        int caCount = trustManager.getAcceptedIssuers().length;
        // An empty but structurally valid keystore initializes fine, so the anchors are counted too
        if (caCount == 0) {
            throw new IllegalStateException("Default trust store contains no CA certificates");
        }
        System.out.println("TRUST STORE OK: " + caCount + " CA certificates");
    }
}
