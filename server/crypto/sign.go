package crypto

import (
	"crypto/ed25519"
	"crypto/rand"
	"errors"
	"io/ioutil"
)

// GenerateKeyPair creates a new Ed25519 key pair for plugin signing.
func GenerateKeyPair() (ed25519.PublicKey, ed25519.PrivateKey, error) {
	pub, priv, err := ed25519.GenerateKey(rand.Reader)
	return pub, priv, err
}

// SignFile signs the contents of a file and returns the signature.
func SignFile(priv ed25519.PrivateKey, filePath string) ([]byte, error) {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return nil, err
	}
	sig := ed25519.Sign(priv, data)
	return sig, nil
}

// VerifyFile checks the signature of a file against a public key.
func VerifyFile(pub ed25519.PublicKey, filePath string, sig []byte) error {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return err
	}
	if !ed25519.Verify(pub, data, sig) {
		return errors.New("invalid signature")
	}
	return nil
}
