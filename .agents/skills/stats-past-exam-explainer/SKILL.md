---
name: stats-past-exam-explainer
description: Analyzes past exam problems for the Statistical Test Grade Pre-1. It creates comprehensive explanation materials for the problem while simultaneously identifying and resolving the user's specific weak points. Compiles everything into a structured LaTeX PDF document in a dedicated directory. This skill is designed to be used when a user asks "過去問解説" or indicates they made a mistake on a past exam problem.
license: MIT
---

# Statistics Pre-1 Past Exam Explainer & Weakness Resolver

This skill is designed to explain past exam problems (過去問) for the Statistical Test Grade Pre-1 (統計検定準一級). Rather than just providing the correct answer, it serves a dual purpose:

1. **Create universally clear explanation materials (解説資料)** for the problem itself.
2. **Identify and resolve the user's specific weak points (ウィークポイントの洗い出しと解決)** based on their mistakes or conceptual blocks.

## Core Workflow

When a user asks about a past exam problem (e.g., "2021年6月の問1を教えて", "この過去問で間違えました"), strictly follow these steps:

### 1. Identify the Problem and User's State

- **When an image or image folder is provided:**
  - **CRITICAL FIRST STEP:** You MUST run the shared conversion script before reading the images: `uv run .agents/shared/statistics-scripts/run_tool.py convert_to_jpg {folder_name}`. This Python wrapper automatically detects the OS and delegates to the shared implementation under `.agents/shared/statistics-scripts/`.
  - _Then_, use the vision capabilities to read the converted `.jpg` images. Do NOT attempt to read images directly before running the conversion script.
  - Analyze the images to understand the specific past exam problem and the user's attempted solution.
- **When text/reference is provided:**
  - Retrieve the problem statement or context to the best of your knowledge.
- **In all cases:** Identify exactly what fundamental knowledge the user is lacking that caused the mistake (**足りない知識** / **ウィークポイント**).

### 2. Output Structure & Output Files

Generate a highly structured response to the user, AND simultaneously create a LaTeX document to compile these insights.

- **Directory Setup:** Create a new directory under `src/past-exams/` for the specific past exam problem (e.g., `src/past-exams/2021-06-q1/`). Within it, create a `figures/` directory.
- **Shared Script Policy:** Reuse the shared script implementations under `.agents/shared/statistics-scripts/`. Do not fork helper logic inside this skill directory.
- **First-time use:** Do not assume any existing `.tex` file already exists under `src/`. Start from the generalized template in `.agents/skills/stats-past-exam-explainer/assets/template.tex`.

The text output and the LaTeX document MUST be structured into two main parts with the following sections in order:

#### Part A: 過去問完全解説 (Complete Problem Explanation)

This part focuses on clearly explaining the problem itself.

- **① 解法の全体フロー (Solution Flow):**
  - Provide a bird's-eye view of the steps to solve the problem before jumping into formulas. (e.g., "Step 1: finding the likelihood -> Step 2: taking the log -> Step 3: differentiating").
- **② 詳細なステップバイステップ解答 (Detailed Step-by-Step Solution):**
  - Derive the answer mathematically. Include all intermediate algebraic manipulations. Never skip steps that might confuse a learner.

#### Part B: ウィークポイント攻略 (Weakness Resolution)

This part focuses on fixing the user's specific misunderstandings.

- **③ あなたのつまずきポイント (Your Stumbling Block):**
  - Explicitly state the "root cause" of the user's mistake. Analyze _why_ they likely made that error (e.g., confusing two distributions, math error, misunderstanding the boundary condition).
- **④ 知識のアップデート (Knowledge Update - Formulas & Triggers):**
  - **着眼点 (Triggers):** Explicitly verbalize the rule. "If you see 'condition X', you should immediately consider 'Y'".
  - **必須公式 (Required Formulas):** List the necessary formulas, exactly when to use them, and the definitions of their variables.
  - **比較学習 (Contrastive Learning):** Compare the correct method with what the user incorrectly applied, explaining the boundary conditions (Why doesn't method X work here?).
- **⑤ 直感的ビジュアル解説 (Visual Explanation for Intuition):**
  - **Choose the Right Drawing Method:** Prefer **TikZ** for concept diagrams, flowcharts, distribution-selection maps, dependency diagrams, and any figure where text layout and mathematical notation quality matter more than sampled numeric geometry. Use a custom Python script only for numerically generated plots such as density curves, shaded rejection regions, simulation visuals, scatter plots, histograms, and other data-driven graphics.
  - **If Python is needed:** Write a custom Python script to generate the graph. Save it in the new directory (e.g., `src/past-exams/2021-06-q1/plot_weakness.py`).
  - **Python Implementation Requirements:** Use `numpy`, `matplotlib.pyplot`, `scipy.stats`, and `import matplotlib_fontja` (for Japanese labels). Save output as `.jpg` and `.pdf` inside `figures/`.
  - **If TikZ is used:** Embed the figure directly in the `.tex` file or factor it into a dedicated `.tex` snippet that is `\input` from the main document. Use TikZ when Python output would become cluttered due to many labels, formulas, arrows, or explanatory boxes.
  - **Self-Review:** Review every generated visual before proceeding. For Python-generated figures, open the `.jpg` with the read tool to verify Japanese text works, math regions are correct, and no overlap occurs. For TikZ figures, compile the PDF and visually inspect the rendered output for overlap, broken alignment, or unreadable formulas. Fix and rerun if necessary.
  - Include an explanation of the visual in text ("このグラフの〇〇の部分が示しているのは..."). Let the user see the connection between the formula and the visual.
- **⑥ 類題による定着確認 (Similar Practice Problem):**
  - Generate a brand new problem that tests the _exact same concept_ targeted at the weakness, but with different numbers or a slightly different context.
  - Provide a complete solution for the new problem to solidify the learning.

### 3. Compile LaTeX Document

- **Create `.tex` File:** In the created directory, create a `.tex` file (e.g., `past-exam-2021-06-q1.tex`).
- **Layout:**
  - Use the standard `jlreq` document class. Do not use `tcolorbox` or other boxed section containers.
  - When the visual is a concept map, flowchart, or formula-heavy relationship diagram, prefer rendering it with TikZ inside LaTeX rather than drawing it in Python.
  - Structure the document using `\section*{過去問解説}` for Part A and `\section*{ウィークポイント攻略}` for Part B.
  - Use plain section headings, bold lead-in labels, `itemize` / `enumerate`, tables, and light horizontal rules instead of boxed environments.
  - Embed the generated visual using `\includegraphics`.
  - Copy and adapt `.agents/skills/stats-past-exam-explainer/assets/template.tex` rather than searching for an older workbook or explanation file.
- **Local References Only:** If guidance is needed, only refer to files inside `.agents/skills/stats-past-exam-explainer/assets/` and `.agents/skills/stats-past-exam-explainer/references/`.
- **Compile:** Run `lualatex` in that directory to generate the PDF.
  ```bash
  cd src/past-exams/{folder-name}
  lualatex {filename}.tex
  ```

### 4. Writing Style for the PDF

- Use typographic hierarchy instead of decorative boxes: `\section*`, `\subsection*`, `\subsubsection*`, and bold labels such as `\noindent\textbf{解法の全体フロー}`.
- Separate major blocks with `\medskip`, `\smallskip`, and `\rule{\linewidth}{0.4pt}` only when it improves readability.
- For trigger/formula summaries and stumbling-block analysis, use structured bullets rather than framed callout boxes.
- Use `.agents/skills/stats-past-exam-explainer/references/structure-guidelines.md` as the in-skill reference for document structure and section depth.

## Tone and Style

- **Encouraging but Rigorous:** Acknowledge that the concept is advanced (Grade Pre-1), but be uncompromising on mathematical correctness. Act as an expert tutor.
- **Language:** All communication MUST be in natural, professional Japanese.
- **Clarity:** Always prioritize the user's understanding of the _underlying principle_ over just finishing the problem. Break down complex derivations into smaller, logical steps. Never skip algebraic manipulations that might confuse the user.
