---
name: stats-workbook-builder
description: Converts problem images into a detailed LaTeX workbook specifically designed for Statistical Test Grade Pre-1 (統計検定準一級) preparation. Focuses on maximizing learning effectiveness through detailed explanations, strategic review points, and conceptual connections. After delivering the workbook, it may optionally suggest the weakness-analyzer if the user still wants a separate weakness-remediation handout for a specific topic.
---

# Statistics Pre-1 Workbook Builder

This skill is specialized for creating high-quality study materials for the **Statistical Test Grade Pre-1 (統計検定準一級)**. It converts problem images into a structured LaTeX document, but goes beyond simple transcription by enforcing a specific pedagogical strategy to maximize learning retention.

## Core Workflow

1.  **Analyze Images**: Scan the target directory under `images/`, using a relative path such as `images/{relative_path}`. Nested subdirectories are allowed.
    - **Image Conversion**: If images are in **HEIC or PNG** format, run the OS-aware wrapper: `uv run .agents/shared/statistics-scripts/run_tool.py convert_to_jpg {relative_path}`. For example, if images are in `images/textbook/22-pca`, run the script with `textbook/22-pca` as the argument. This converts files to JPG and **deletes the original source files** to keep the workspace clean.
    - **Figure Extraction**: After conversion (or immediately if images are already JPG), run the OS-aware wrapper: `uv run .agents/shared/statistics-scripts/run_tool.py extract_figures {relative_path} src/textbook/{ChapterNumber}-{Topic}`. This saves cropped figures to `src/textbook/{ChapterNumber}-{Topic}/figures/` for use with `\includegraphics`. Review the extracted figures and delete any false positives.
2.  **Extract & Filter Content**:
    - **Scope**: Extract both **standard problems (問 X.Y)** and **example problems (例 X)**. Treat examples with the same rigorous detail as problems.
    - **NO External OCR**: Do NOT use external OCR tools. As an AI agent, use your own vision capabilities to read the mathematical content directly from the images.
    - **Infer Context**: Analyze the image content to determine the appropriate Chapter Number and Topic Name (e.g., if the image is about "Bayes' Theorem" and labeled "1.1", infer `1-probability`).
    - **CRITICAL**: Include **ALL** problems, including "**Examples**" (例題) and "**Questions**" (問). Do NOT skip Example problems as they often contain foundational concepts.
    - **Ignore**: Non-problem text (dates, page numbers, unrelated scribbles). Focus purely on the mathematical content.
3.  **Enhance Content (The Learning Strategy)**:
    - **Detailed Solutions**: Expand the original solution. Do not skip steps. Explain _why_ a particular transformation or formula is used.
    - **Learner Diagnosis**: For each problem, infer the most likely conceptual obstacle before writing the solution: definition recall, formula selection, algebra/calculus execution, condition checking, interpretation, or exam-time strategy. Use that diagnosis to decide what to emphasize.
    - **Visual Aids**: Choose the drawing method intentionally. Prefer **TikZ** for concept diagrams, flowcharts, dependency diagrams, estimator-selection maps, and any figure where mathematical notation and label placement matter more than sampled numeric geometry. Use custom Python scripts only for numerically generated plots such as distributions, confidence intervals, rejection regions, scatter plots, histograms, simulations, and other data-driven graphics. Place any custom scripts alongside the `.tex` files for clarity and reproducibility.
    - **Conceptual Connections**: Link the problem to broader statistical concepts (e.g., "This is an application of the Central Limit Theorem," or "This relates to the properties of MLE").
    - **Active Recall Prompts**: Add short prompts in the solution or review point that make the learner retrieve the key idea before seeing the final rule, such as "ここで確認: なぜ正規分布ではなく t 分布を使うか".
    - **Review Points**: Create a specific "Review Point" section for _every_ problem, including how to recognize the same pattern in a new problem.
4.  **Directory Structure & File Naming**:
    - **Self-Determine**: The AI agent must decide the correct `{ChapterNumber}-{Topic}` based on the analysis of the images (e.g., if the problem is about "Distributions", use `2-distributions`).
    - **Root Directory**: Create a `src/textbook` directory if it doesn't exist.
    - **Subfolder**: Create a subdirectory inside `src/textbook` naming it `{ChapterNumber}-{Topic}`.
    - **Main File**: Inside that subdirectory, create the main `{ChapterNumber}-{Topic}.tex` file.
    - **Work within Subfolder**: Run compilation and store all auxiliary files within this subdirectory. This keeps the project clean and facilitates future merging.
5.  **Generate LaTeX**:
    - **First-time use**: Do not inspect or depend on any existing `.tex` file under `src/textbook/` or elsewhere in the repository. Start from the generalized template at `.agents/skills/stats-workbook-builder/assets/template.tex`.
    - **Problem Section**: List all problems first. Header format: `\subsection*{問 X.Y}` (Do NOT include the topic name to force active recall).
    - `\newpage` to separate sections.
    - **Solution Section**: List all detailed solutions using plain section headings, short lead-in labels, `itemize`/`enumerate`, tables, and horizontal rules. Do not divide sections with `tcolorbox` or other boxed containers.
6.  **Compile**: Use `lualatex` to generate the PDF within the subdirectory.

## Post-Delivery UX: Optional Handoff to Weakness Analyzer

After you deliver the workbook, use the following behavior:

- If the user asks a small follow-up question about one line, one formula, or one step, answer directly in chat. Do **not** create another PDF or push a new workflow.
- If the user says they still do not understand a specific point after reviewing the workbook, you may add one short optional suggestion such as:
  - `必要なら、この論点だけを切り出した苦手対策資料も作れます。`
  - `たとえば「主成分分析の寄与率の苦手対策資料を作成して」のように言ってもらえれば、そこだけに絞って作れます。`
- Offer that suggestion only after the workbook has been produced and only when it fits the user's state.
- Do not activate `stats-weakness-analyzer` unless the user explicitly asks for the dedicated weakness-remediation material.

## Learning Maximization Strategy for Solutions

To ensure the user can **master the topic without referring to a textbook**, solutions must adhere to the following principles:

### 1. The "Why" Before the "How"

- Before diving into calculation, briefly state the **strategy**.
- _Bad_: "We use formula X."
- _Good_: "Since we are dealing with a small sample size and unknown population variance, we must use the t-distribution. The test statistic is given by..."

### 2. Explicit Intermediate Steps

- Never skip algebraic manipulations.
- _Bad_: "Substituting values, we get 0.05."
- _Good_: "Substituting $\bar{x}=5, \mu=0, s=2, n=16$:
  $$ t = \frac{5 - 0}{2 / \sqrt{16}} = \frac{5}{0.5} = 10 $$"

### 3. Review Points for Retention (Enriched)

- **Comprehensive Coverage**: Do not just write one sentence. A Review Point should be a rich summary of the topic.
- **Structure**: Use `itemize` or `enumerate` to break down concepts.
  - **Definitions**: Clearly state the definitions used.
  - **Intuition**: Explain the "heart" of the concept (e.g., "Standardization shifts the center to 0 and scales the spread to 1").
  - **Pitfalls**: Explicitly mention common mistakes.
  - **Visuals**: Describe the shape of distributions or properties.
- **Reference**: Use `.agents/skills/stats-workbook-builder/references/review-point-guidelines.md` as the local reference for Review Point depth and structure.

### 4. Transfer and Exam Readiness

- Add one compact "recognition cue" for every problem: what wording, statistic, graph, or condition should make the learner choose this method.
- When two methods are easily confused, include a one- or two-row contrast table such as "use this when..." versus "do not use this when...".
- End each solution with a brief self-check question that the learner can answer without looking back at the derivation.
- Keep these additions concise. They should deepen learning without turning every problem into a separate lecture.

### 5. Solution Quality Checklist

Before compiling, verify that each solution:

- States the solving strategy before calculation.
- Names the theorem, distribution, estimator, or testing framework being used.
- Checks required assumptions or applicability conditions when relevant.
- Shows substitutions and algebraic transformations explicitly.
- Interprets the final numeric or symbolic answer in the language of the problem.
- Includes a review point with definition, intuition, pitfall, and transfer cue.

## Configuration & Style Guide

### Output Structure

All work must happen in `src/textbook/{ChapterNumber}-{Topic}/`.

- Example:
  ```
  src/
  └── textbook/
      └── 1-probability/
          ├── 1-probability.tex
          └── 1-probability.pdf
  ```

### LaTeX Structure

- **Document Class**: `jlreq` (for Japanese support).
- **Packages**:
  - Keep the preamble minimal and readable. Do not introduce `tcolorbox` for section separation.
  - Include TikZ when the explanation benefits from concept diagrams or flow-oriented visuals.
- **Geometry**: Standard A4 margins (`left=25mm, right=25mm, top=30mm, bottom=30mm`).
- **Structure**:
  - Problem Section (No answers visible).
  - `\newpage`
  - Solution & Explanation Section.
- **Template Source**: Copy and adapt `.agents/skills/stats-workbook-builder/assets/template.tex`. Do not search for an existing workbook under `src/textbook/` as a starting point.
- **Local References Only**: If guidance is needed, only refer to files inside `.agents/skills/stats-workbook-builder/assets/` and `.agents/skills/stats-workbook-builder/references/`.

### Content Rules

- **Problem Headers**: `\subsection*{問 X.Y}` or `\subsection*{例題 X}`.
- **Section Presentation**:
  - Use typographic hierarchy instead of boxes: `\section`, `\subsection*`, `\subsubsection*`, bold labels such as `\noindent\textbf{方針}` and `\noindent\textbf{復習ポイント}`.
  - Use `\medskip`, `\smallskip`, and `\hrule` / `\rule{\linewidth}{0.4pt}` sparingly to separate major blocks.
  - Prefer `itemize`, `enumerate`, and short paragraphs over decorative framing.

## Visualization Strategy

When solutions benefit from visual aids, choose between **TikZ** and **Python plotting** based on the nature of the figure. Do not default to Python for every visualization.

### Choose the Right Drawing Method

Prefer **TikZ** when:

- The figure is a concept diagram, flowchart, dependency map, decision chart, or formula relationship diagram.
- Text layout, arrows, grouping, and mathematical notation quality are more important than numeric sampling.
- The visual should blend tightly with surrounding LaTeX typography.

Prefer **Python** when:

- The figure is driven by numeric values or sampled geometry.
- You need probability density curves, rejection regions, simulation visuals, scatter plots, histograms, regression lines, or confidence interval plots.
- The visual is easier to generate from code than to hand-draw in TikZ.

### TikZ Workflow

If TikZ is the better fit:

- Embed the diagram directly in the main `.tex` file, or factor it into a dedicated snippet such as `figures/concept_map.tex` and include it with `\input`.
- Keep diagrams structurally simple and readable. Avoid overcrowding nodes or labels.
- After compiling, visually inspect the rendered PDF and fix overlap, broken alignment, or unreadable formulas.

### Python Workflow: Custom Visualization Scripts

**Philosophy**: Instead of using fixed, generic plotting scripts, create **problem-specific Python scripts** within each problem's subfolder. This provides maximum flexibility and clarity.

**Step 1: Create a custom script** in the problem's directory:

```
src/textbook/01-probability/
├── problem.tex
├── solution.tex
├── figures/
│   └── normal_dist.pdf        # Generated output
└── plot_normal_dist.py         # Custom script for this problem
```

**Step 2: Write the visualization script** using the available Python environment:

```python
#!/usr/bin/env python3
"""Custom visualization for Problem 1: Normal Distribution Properties"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
import matplotlib_fontja  # Japanese font support

# Problem-specific parameters
mu = 50
sigma = 10

# Generate plot
x = np.linspace(mu - 4*sigma, mu + 4*sigma, 1000)
y = stats.norm.pdf(x, mu, sigma)

plt.figure(figsize=(8, 6))
plt.plot(x, y, 'b-', linewidth=2)
plt.fill_between(x, y, alpha=0.2)
plt.axvline(mu, color='r', linestyle='--', label=f'平均 μ={mu}')
plt.xlabel('値')
plt.ylabel('確率密度')
plt.title(f'正規分布 N({mu}, {sigma}²)')
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('figures/normal_dist.pdf', bbox_inches='tight', dpi=300)
print("Generated: figures/normal_dist.pdf")
```

**Step 3: Run the script** using the project's Python environment:

```bash
cd src/textbook/01-probability
uv run plot_normal_dist.py
```

**Step 4: Reference in LaTeX**:

```latex
\begin{center}
  \includegraphics[width=0.7\linewidth]{figures/normal_dist.pdf}\\
  図: 正規分布 N(50, 10²) の確率密度関数。赤線は平均値を示す。
\end{center}
```

### Python Environment Setup

Use the shared repository Python environment defined under `setup/`.

If only the Python plotting / figure-extraction environment is needed:

```bash
bash setup/setup_mac.sh
```

If the machine itself still needs TeX/uv setup, use the higher-level OS bootstrap script instead:

```bash
bash setup/setup_mac.sh
```

or on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File setup/setup_windows.ps1
```

The relationship is:

- `setup/requirements.lock` defines the shared Python dependencies used by multiple skills.
- `setup/setup_mac.sh` and `setup/setup_windows.ps1` are the machine setup entry points that create `.venv` and sync those shared dependencies.

The shared Python environment creates a `.venv` with:

- **Plotting**: matplotlib, seaborn, scipy, numpy, pandas
- **Japanese support**: matplotlib-fontja
- **Image processing**: opencv, torch, transformers (for figure extraction)

**Available in all custom scripts**:

```python
import numpy as np              # Numerical computing
import matplotlib.pyplot as plt # Plotting
import seaborn as sns          # Statistical visualizations
from scipy import stats        # Statistical functions
import pandas as pd            # Data manipulation
import matplotlib_fontja       # Japanese font support
```

### Benefits of Custom Scripts

- **Flexibility**: Tailor each visualization to the specific problem's needs
- **Clarity**: Script filename and content document what's being visualized
- **Reproducibility**: Script lives alongside the problem, making it easy to regenerate or modify
- **Learning**: Problem-specific code reinforces the concepts being studied

### Self-Review for Visuals

- For Python-generated figures, inspect the output image to verify Japanese text rendering, axis labels, and highlighted regions are correct.
- For TikZ figures, compile the PDF and visually inspect the rendered output for overlap, broken alignment, or unreadable formulas.
- Revise and rerun until the figure is genuinely readable.

## Image Handling

### Figure Extraction (Charts, Graphs, Diagrams)

When images contain charts, graphs, or diagrams that cannot be reasonably reproduced in TikZ, **extract them automatically** using the figure extraction tool.

**Step 1: Run the extraction script** early in the workflow (after conversion, before LaTeX generation):

```bash
uv run .agents/shared/statistics-scripts/run_tool.py extract_figures {relative_path} src/textbook/{ChapterNumber}-{Topic}
```

For example, for `images/textbook/15/`:

```bash
uv run .agents/shared/statistics-scripts/run_tool.py extract_figures textbook/15 src/textbook/15-stochastic-processes
```

This outputs cropped figure images to `src/textbook/{ChapterNumber}-{Topic}/figures/` and prints a JSON manifest listing extracted files.

**Step 2: Review extracted figures.** Read each output image to verify it was correctly cropped. Discard false positives (e.g., decorative images or header logos) by deleting them from the `figures/` directory.

**Step 3: Use `\includegraphics` in LaTeX.** Reference figures from the `figures/` subdirectory:

```latex
\begin{center}
  \includegraphics[width=0.7\linewidth]{figures/IMG_7473.jpg}\\
  図15.2 不良品を100個みつけるまでの時間 (横軸) と累積数 (縦軸) のグラフ.
\end{center}
```

Add `\graphicspath{{./}}` in the preamble if not already present, so that relative paths resolve correctly when compiling from the subdirectory.

**Step 4: Caption from context.** Read the surrounding text in the source image (the model also detects `figure_title` regions) to write an accurate Japanese caption beneath the figure.

### Text Extraction

When extracting text:

- **Ignore**: Handwriting that looks like scribbles, dates, or unrelated text.

## Compilation Command

Run `lualatex` inside the specific subdirectory.

```bash
cd src/textbook/1-probability
lualatex 1-probability.tex
```
