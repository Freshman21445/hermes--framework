package main

import (
	"flag"
	"fmt"
	"os"

	"hermes/server/crypto"
)

func main() {
	gen := flag.Bool("gen", false, "generate key pair")
	sign := flag.String("sign", "", "sign a plugin file")
	pubKeyFile := flag.String("pub", "public.pem", "public key file")
	privKeyFile := flag.String("priv", "private.pem", "private key file")
	flag.Parse()

	if *gen {
		pub, priv, err := crypto.GenerateKeyPair()
		if err != nil {
			fmt.Println("Error:", err)
			os.Exit(1)
		}
		// Save keys to files (PEM encoding)
		os.WriteFile(*pubKeyFile, pub, 0644)
		os.WriteFile(*privKeyFile, priv, 0600)
		fmt.Println("Key pair generated.")
		return
	}

	if *sign != "" {
		privBytes, err := os.ReadFile(*privKeyFile)
		if err != nil {
			fmt.Println("Error reading private key:", err)
			os.Exit(1)
		}
		priv := ed25519.PrivateKey(privBytes)
		sig, err := crypto.SignFile(priv, *sign)
		if err != nil {
			fmt.Println("Error signing file:", err)
			os.Exit(1)
		}
		fmt.Printf("Signature (hex): %x\n", sig)
	}
}
