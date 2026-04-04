---
name: stats-weakness-analyzer
description: Analyzes incorrect answers from the Statistical Test Grade Pre-1 workbook, identifies core weaknesses, provides necessary formulas, generates visual explanations, creates similar practice problems, and compiles everything into a LaTeX PDF document in a dedicated directory. Use this skill when the user reports a problem they got wrong or asks for help understanding their mistake.
license: MIT
---

# Statistics Pre-1 Weakness Analyzer

This skill is designed to provide targeted support when a user answers a problem incorrectly in the Statistical Test Grade Pre-1 (統計検定準一級) workbook. Its goal is to fundamentally resolve the user's weakness rather than just providing the correct answer, and to document this analysis as a compiled PDF.

## Core Workflow

When a user reports that they made a mistake on a specific problem (e.g., "問 2.3 を間違えた", "〇〇の概念がわからない"), strictly follow these steps:

### 1. Identify the Problem and Context
*   Locate the original problem in the corresponding LaTeX file within the `src/` directory.
*   Understand the entire context of the problem, the correct solution, and where the user might have gone wrong (especially if they shared their thought process).
*   If the user provides an image folder instead of a text reference, first normalize the images using the shared conversion script: `uv run .agents/shared/statistics-scripts/run_tool.py convert_to_jpg {folder_name}`. This Python wrapper automatically detects the OS and delegates to the shared implementation under `.agents/shared/statistics-scripts/`.

### 2. Output Structure & Output Files
Generate a highly structured response to the user, AND simultaneously create a LaTeX document to compile these insights.
*   **Directory Setup:** Create a new directory under `src/weakness-analysis/` for the specific problem or concept (e.g., `src/weakness-analysis/q2-3-distributions/`). Within it, create a `figures/` directory.
*   **Shared Script Policy:** Reuse the shared script implementations under `.agents/shared/statistics-scripts/`. Do not duplicate the core logic inside this skill directory.
*   **First-time use:** Do not assume any existing `.tex` file already exists under `src/`. Start from the generalized template in `.agents/skills/stats-weakness-analyzer/assets/template.tex`.

The content MUST use the following four sections in order, in both your chat response and the LaTeX document:

#### ① 苦手分析 (Weakness Analysis)
*   **Identify the Root Cause:** Pinpoint exactly what conceptual misunderstanding, theoretical gap, or calculation error likely led to the mistake.
*   **Conceptual Shift:** Explain *why* this gap is a common pitfall. Point out what the user needs to shift in their mental model to stop making this exact mistake.

#### ② 覚えるべき公式 (Formulas to Memorize)
*   List explicitly the formulas and theorems that are essential for solving this type of problem.
*   Include not just the mathematical formula, but a brief note on **when to use it (適用条件)** and the **meaning of its variables (変数の意味)**.
*   Use standard LaTeX formatting for all math blocks.

#### ③ ビジュアル解説 (Visual Explanation for Intuition)
*   **Visual Strategy:** Math without intuition is hard to remember. Devise a visual way to explain the core concept (e.g., probability distribution shapes, integration regions, regression lines, confidence intervals, geometry of vectors).
*   **Choose the Right Drawing Method:** Prefer **TikZ** for concept diagrams, cheat sheets, distribution-selection maps, formula relationship charts, and other annotation-heavy visuals. Use a custom Python script only when the figure is fundamentally numeric or sampled from functions, such as density curves, confidence interval shading, scatter plots, histograms, regression visuals, or simulation output.
*   **If Python is needed:** Write a custom Python script to generate the explanatory graph. Save it in the new directory (e.g., `src/weakness-analysis/q2-3-distributions/plot_weakness_explain.py`).
*   **Python Implementation Requirements:**
    *   Use `numpy`, `matplotlib.pyplot`, and `scipy.stats`.
    *   MUST use `import matplotlib_fontja` so Japanese labels render correctly.
    *   Use shading (`fill_between`), clear annotations, and colors to highlight the specific concept they struggled with.
*   **If TikZ is used:** Create the figure directly in the `.tex` document or in a separate `.tex` snippet included from it. Prefer TikZ whenever Python would make the layout cluttered because of many text labels, formulas, boxes, or arrows.
*   **Execution:** Run the script using the project's Python environment. Save each figure in two formats:
    *   **JPG** (`figures/*.jpg`) — for self-review (use `plt.savefig(..., format='jpg')` directly).
    *   **PDF** (`figures/*.pdf`) — for inclusion in the LaTeX document via `\includegraphics`.
*   **Self-Review of Generated Graph:** After generating visuals, you MUST inspect them before proceeding. For Python-generated graphs, open every JPG in the `figures/` directory using the Read tool. For TikZ figures, compile the PDF and inspect the rendered output. Verify the following for each graph:
    *   Labels, titles, and annotations are readable and not overlapping or cut off.
    *   The mathematical content shown (shaded regions, curves, values) is correct and matches the formulas from step ②.
    *   Colors and legends are distinguishable and meaningful.
    *   Japanese text renders properly (not garbled or missing).
    *   The graph effectively communicates the intended concept to the user.
    *   If any issue is found, fix the Python script and re-generate until the graph passes review.
*   **Explain the Visual:** After generating and verifying the plot, explain it in text: "このグラフの赤い斜線部分が示しているのは..." (The red shaded area in this graph shows...). Let the user see the connection between the formula and the visual.

#### ④ 類似問題 (Similar Practice Problem)
*   **Generate a New Problem:** Create a brand new problem that tests the *exact same concept* but with different numbers, a slightly different real-world scenario, or by solving for a different variable.
*   **Match Difficulty:** Keep the difficulty level identical to the original Grade Pre-1 problem.
*   **Provide Solution:** Provide a complete, step-by-step detailed solution for the new similar problem. Explicitly demonstrate how to apply the formulas from step ② and how to avoid the trap identified in step ①.

### 3. Compile LaTeX Document
*   **Create `.tex` File:** In the created directory, create a `.tex` file (e.g., `weakness-q2-3.tex`). Use the standard `jlreq` document class. Do not use `tcolorbox` or other boxed section containers.
*   **Layout:** Put the "Weakness Analysis", "Formulas", and "Visual Explanation" in clearly titled sections. Put the "Similar Problem" as a new problem block, and write the similar-problem solution using plain headings, bold lead-in labels, `itemize` / `enumerate`, and short explanatory paragraphs. When the visual is a concept map or formula-heavy explanation diagram, prefer TikZ inside LaTeX; otherwise include Python-generated visuals using `\includegraphics`.
*   **Template Source:** Copy and adapt `.agents/skills/stats-weakness-analyzer/assets/template.tex` rather than searching for an older analysis file.
*   **Local References Only:** If guidance is needed, only refer to files inside `.agents/skills/stats-weakness-analyzer/assets/` and `.agents/skills/stats-weakness-analyzer/references/`.
*   **Compile:** Run `lualatex` in that directory to generate the PDF.
    ```bash
    cd src/weakness-analysis/{folder-name}
    lualatex {filename}.tex
    ```

### 4. Writing Style for the PDF
*   Use typographic hierarchy instead of decorative boxes: `\section*`, `\subsection*`, `\subsubsection*`, and bold labels such as `\noindent\textbf{苦手分析}`.
*   Separate major blocks with `\medskip`, `\smallskip`, and `\rule{\linewidth}{0.4pt}` only when it improves readability.
*   Use bullets for formulas, application conditions, variable meanings, and common pitfalls.
*   Use `.agents/skills/stats-weakness-analyzer/references/structure-guidelines.md` as the in-skill reference for document structure and section depth.

## Tone and Style
*   **Encouraging but Rigorous:** Acknowledge that the concept is advanced (Grade Pre-1), but be uncompromising on mathematical correctness. Act as an expert tutor.
*   **Language:** All communication MUST be in natural, professional Japanese.
*   **Clarity:** Break down complex derivations into smaller, logical steps. Never skip algebraic manipulations that might confuse the user.
