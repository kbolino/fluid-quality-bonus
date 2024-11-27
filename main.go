package main

import (
	"archive/zip"
	"embed"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path"
	"strings"
)

//go:embed src
var srcFS embed.FS

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "FATAL:", err)
		os.Exit(1)
	}
}

func run() (err error) {
	modBase := fmt.Sprintf("%s_%s", thisInfo.Name, thisInfo.Version)
	outPath := fmt.Sprintf("%s.zip", modBase)
	outFile, err := os.Create(outPath)
	if err != nil {
		return fmt.Errorf("opening output file %q for writing: %w", outPath, err)
	}
	defer func() {
		if closeErr := outFile.Close(); closeErr != nil && err == nil {
			err = fmt.Errorf("closing output file %q: %w", outPath, err)
		}
	}()
	zipWriter := zip.NewWriter(outFile)
	defer func() {
		if closeErr := zipWriter.Close(); closeErr != nil && err == nil {
			err = fmt.Errorf("closing ZIP file: %w", err)
		}
	}()
	infoWriter, err := zipWriter.Create(path.Join(modBase, "info.json"))
	if err != nil {
		return fmt.Errorf("creating info.json: %w", err)
	}
	infoBytes, err := json.Marshal(thisInfo)
	if err != nil {
		return fmt.Errorf("marshing info as JSON: %w", err)
	}
	_, err = infoWriter.Write(infoBytes)
	if err != nil {
		return fmt.Errorf("writing info.json bytes: %w", err)
	}
	fs.WalkDir(srcFS, "src", func(p string, d fs.DirEntry, _ error) error {
		if d.IsDir() {
			return nil
		}
		file, err := srcFS.Open(p)
		if err != nil {
			return fmt.Errorf("opening file %q for reading: %w", p, err)
		}
		defer file.Close()
		zipPath := modBase + strings.TrimPrefix(p, "src")
		fileWriter, err := zipWriter.Create(zipPath)
		if err != nil {
			return fmt.Errorf("creating file %q in ZIP from %q: %w", zipPath, p, err)
		}
		_, err = io.Copy(fileWriter, file)
		if err != nil {
			return fmt.Errorf("copying file %q to %q in ZIP: %w", p, zipPath, err)
		}
		return nil
	})
	return nil
}
