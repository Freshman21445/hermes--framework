package db

import (
	"log"

	bolt "go.etcd.io/bbolt"
)

var (
	DB *bolt.DB
)

// Init opens the BoltDB database and creates necessary buckets.
func Init(path string) error {
	var err error
	DB, err = bolt.Open(path, 0600, nil)
	if err != nil {
		return err
	}

	// Create buckets
	return DB.Update(func(tx *bolt.Tx) error {
		for _, bucket := range []string{"agents", "tasks", "results"} {
			if _, err := tx.CreateBucketIfNotExists([]byte(bucket)); err != nil {
				return err
			}
		}
		return nil
	})
}

func Close() {
	if DB != nil {
		DB.Close()
	}
}
