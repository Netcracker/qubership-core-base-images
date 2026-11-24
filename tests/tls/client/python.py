import os
import ssl
from urllib.error import URLError
from urllib.request import urlopen

expect_untrusted = os.environ.get("EXPECT_UNTRUSTED") == "1"
try:
    with urlopen(os.environ["URL"], timeout=5) as response:
        assert response.status == 200
        assert response.read() == b"OK"
except URLError as error:
    if not expect_untrusted or not isinstance(error.reason, ssl.SSLCertVerificationError):
        raise
else:
    assert not expect_untrusted, "HTTPS succeeded before the CA was imported"
