package main

import (
	"flag"
	"fmt"
	"sort"
	"strings"
	"unicode"

	"github.com/laspp/PS-2023/vaje/naloga-1/koda/xkcd"
)

func sanitize(str string) []string {
	lower := strings.ToLower(str)

	return strings.FieldsFunc(lower, func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsNumber(r)
	})
}

func wordsInComic(id int) map[string]int {
	comic, err := xkcd.FetchComic(id)
	if err != nil {
		panic(err)
	}

	sanitized := sanitize(comic.Title)
	if comic.Transcript != "" {
		sanitized = append(sanitized, sanitize(comic.Transcript)...)
	} else {
		sanitized = append(sanitized, sanitize(comic.Tooltip)...)
	}

	words := make(map[string]int)
	for _, word := range sanitized {
		if len(word) >= 4 {
			words[word]++
		}
	}

	return words
}

func printTop(freqs map[string]int, n int) {
	type wordFreq struct {
		word string
		freq int
	}

	wfs := make([]wordFreq, 0, len(freqs))
	for word, freq := range freqs {
		wfs = append(wfs, wordFreq{word, freq})
	}

	sort.Slice(wfs, func(i, j int) bool {
		return wfs[i].freq > wfs[j].freq ||
			(wfs[i].freq == wfs[j].freq && wfs[i].word < wfs[j].word)
	})

	for _, wf := range wfs[:n] {
		fmt.Printf("%s, %d\n", wf.word, wf.freq)
	}
}

func main() {
	numGoroutines := flag.Int("goroutines", 100, "amount of goroutines")
	flag.Parse()

	comic, err := xkcd.FetchComic(0)
	if err != nil {
		panic(err)
	}

	numComics := comic.Id

	if *numGoroutines > numComics {
		*numGoroutines = numComics
	} else if *numGoroutines < 1 {
		*numGoroutines = 1
	}

	ch := make(chan map[string]int)

	for i := 0; i < *numGoroutines; i++ {
		go func(i int, ch chan<- map[string]int) {
			startId := numComics*i / *numGoroutines + 1
			endId := numComics * (i + 1) / *numGoroutines

			for id := startId; id <= endId; id++ {
				ch <- wordsInComic(id)
			}
		}(i, ch)
	}

	freqs := make(map[string]int)
	for i := 0; i < numComics; i++ {
		words := <-ch
		for word, freq := range words {
			freqs[word] += freq
		}
	}

	printTop(freqs, 15)
}
