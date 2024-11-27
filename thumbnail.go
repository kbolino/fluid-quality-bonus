package main

import (
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"os"
	"path/filepath"

	"github.com/disintegration/imaging"
)

var anyQualityPath = []string{
	"data", "core", "graphics", "icons", "any-quality.png",
}

var baseFluidPath = []string{
	"data", "space-age", "graphics", "icons", "fluid", "holmium-solution.png",
}

func generateThumbnail(gameDir string) (image.Image, error) {
	// read images from game data

	pathElems := []string{gameDir}
	pathElems = append(pathElems, baseFluidPath...)
	baseFluidImage, err := readPNG(filepath.Join(pathElems...))
	if err != nil {
		return nil, fmt.Errorf("reading base fluid image: %w", err)
	}
	pathElems = []string{gameDir}
	pathElems = append(pathElems, anyQualityPath...)
	anyQualityImage, err := readPNG(filepath.Join(pathElems...))
	if err != nil {
		return nil, fmt.Errorf("reading any-quality emblem image: %w", err)
	}

	// base fluid is likely a mipmap, so ignore the smaller sizes
	croppedBounds := baseFluidImage.Bounds()
	croppedBounds.Max.X = croppedBounds.Max.Y
	baseFluidCropped := imaging.Crop(baseFluidImage, croppedBounds)

	// start with the fluid image at 2x emblem size
	emblemBounds := anyQualityImage.Bounds()
	width := emblemBounds.Dx() * 2
	height := emblemBounds.Dy() * 2
	resizedFluid := imaging.Resize(baseFluidCropped, width, height, imaging.Gaussian)
	img := imaging.New(width, height, color.Transparent)
	draw.Over.Draw(img, img.Bounds(), resizedFluid, image.Pt(0, 0))

	// overlay the any-quality emblem in the lower-right corner
	bounds := img.Bounds()
	dstRect := image.Rect(bounds.Max.X/2, bounds.Max.Y/2, bounds.Max.X, bounds.Max.Y)
	draw.Over.Draw(img, dstRect, anyQualityImage, image.Pt(0, 0))

	return img, nil
}

func readPNG(filePath string) (image.Image, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("opening file for reading: %w", err)
	}
	defer file.Close()
	img, err := png.Decode(file)
	if err != nil {
		return nil, fmt.Errorf("decoding image as PNG: %w", err)
	}
	return img, nil
}
