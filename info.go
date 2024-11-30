package main

type Info struct {
	Name            string   `json:"name"`
	Version         string   `json:"version"`
	Title           string   `json:"title"`
	Author          string   `json:"author"`
	FactorioVersion string   `json:"factorio_version"`
	Dependencies    []string `json:"dependencies"`
}

var thisInfo = Info{
	Name:            "fluid-quality-bonus",
	Version:         "0.1.0",
	Title:           "Fluid Quality Bonus",
	Author:          "DeathJunkie88",
	FactorioVersion: "2.0",
	Dependencies:    []string{"quality"},
}
