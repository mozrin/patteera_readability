# Patteera Readability

A sophisticated text readability analyzer built with Flutter, based on the specific **Lexical Frequency Profile (LFP)** theories proposed by **Patteera Thienpermpool**.

## 📖 About the Project

This application implements a specific readability scoring algorithm that analyzes text based on vocabulary frequency bands (Level 1, Level 2, Level 3, Medical, Academic, etc.). Unlike standard formulas (like Flesch-Kincaid) that rely on sentence length and syllable counting, this approach evaluates the *quality* and *familiarity* of the vocabulary used.

The core logic aggregates the weighted contribution of words from specific frequency lists to produce a **Readability Score (0-100)**.

- **Higher Score**: Indicates text composed of more familiar/frequent words (Easier to read).
- **Lower Score**: Indicates text with more obscure or off-list vocabulary (Harder to read).

## 🎓 Attribution & Theory

The core scoring methodology and theoretical framework for this application are credited to **Patteera Thienpermpool**.

**Reference Thesis:**
*The Use of Lexical Frequency Profile for Determining text Readability*
[View Full Paper](http://sutir.sut.ac.th:8080/sutir/handle/123456789/4318?mode=full)

> "Higher percentage or scores indicate texts that are easier to read and lower numbers mark texts that are more difficult to read." — *Patteera Thienpermpool*

## ✨ Features

- **LFP-Based Analysis**: Detailed breakdown of text composition across multiple frequency bands.
- **Customizable Weights**: Users can adjust the scoring weight of each band (e.g., make "Medical" words count as "Easy" for a doctor's profile).
- **Optical Character Recognition (OCR)**: Scan physical documents or images directly into the analyzer.
- **Linux Desktop Support**: Native Linux integration including window icons and file system hooks.
- **Beautiful UI**: Modern, dark-themed interface with smooth animations and responsive charts.

## 🛠️ Tech Stack

- **Flutter**: UI Toolkit
- **Hive**: Local persistence for configuration
- **OcrKit / Tesseract**: Image-to-text processing
- **Provider**: State management

---
*Built in collaboration with the research of Patteera Thienpermpool. Used with permission.*
