<!--
sources:
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-4-8
last_fetched: 2026-06-10
cache_ttl_days: 14
models_covered: [Claude Fable 5, Claude Mythos 5, Claude Opus 4.8, Claude Opus 4.7, Claude Opus 4.6, Claude Sonnet 4.6, Claude Haiku 4.5]
prev_version: best-practices-20260610.md
note: 官方文章自 2026-06 起拆为「主文(通用技巧)+ 模型专属子页(Fable 5 / Opus 4.8)」三个页面。
      本缓存按此顺序合并三页:Part 1 主文(通用)、Part 2 Prompting Claude Fable 5、Part 3 Prompting Claude Opus 4.8。
      刷新时必须抓取上面 sources 列出的全部 URL —— 只刷主文会静默丢失模型专属内容;
      同时检查主文里是否出现了新的模型专属子页链接,有则把它加进 sources 一并抓取。
      时间新鲜度:使用前运行 scripts/check_cache_age.sh(默认 TTL 14 天)。
      内容新鲜度:若「执行 skill 的模型」「用户提到的 GA Claude 模型」「被审 prompt 的目标模型」
      任一不在 models_covered 内,即使时间未过期也视为内容陈旧,提示联网刷新(见 SKILL.md 步骤 1.4)。
-->

# Part 1 — Prompting best practices(主文,通用技巧)

Comprehensive guide to prompt engineering techniques for Claude's latest models, covering clarity, examples, XML structuring, thinking, and agentic systems.

---

This is the reference for prompt engineering with Claude's latest models, including Claude Fable 5, Claude Mythos 5, Claude Opus 4.8, Claude Opus 4.7, Claude Opus 4.6, Claude Sonnet 4.6, and Claude Haiku 4.5. The page is organized in three parts:

- **Model-specific guidance** first: where Claude Fable 5 and Claude Opus 4.8 behave differently and what to change.
- **Techniques for all current models** after that: general principles, output and formatting, tool use, thinking, and agentic systems.
- **Migration considerations** last, for prompts moving from earlier generations.

> For an overview of model capabilities, see the models overview. For Claude Fable 5 capabilities and API changes, see "Introducing Claude Fable 5 and Claude Mythos 5". For details on what's new in Claude Opus 4.8, see "What's new in Claude Opus 4.8". For migration guidance, see the Migration guide.

## Claude Fable 5

Prompting guidance for Claude Fable 5 and Claude Mythos 5 has its own page: **Prompting Claude Fable 5**(本缓存 Part 2)。It covers the behavioral differences from Claude Opus 4.8 and the prompt and scaffolding changes worth making, including effort levels, instruction following, long-run progress claims, memory systems, and the `reasoning_extraction` refusal category.

## Prompting Claude Opus 4.8

Prompting guidance for Claude Opus 4.8 has its own page: **Prompting Claude Opus 4.8**(本缓存 Part 3)。It covers response length, effort and thinking-depth calibration, tool use triggering, literal instruction following, subagent control, and design and frontend defaults.

## General principles

The techniques in this section and the sections that follow apply to all current Claude models, including Claude Fable 5 and Claude Mythos 5.

### Be clear and direct

Claude responds well to clear, explicit instructions. Being specific about your desired output can help enhance results. If you want "above and beyond" behavior, explicitly request it rather than relying on the model to infer this from vague prompts.

Think of Claude as a brilliant but new employee who lacks context on your norms and workflows. The more precisely you explain what you want, the better the result.

**Golden rule:** Show your prompt to a colleague with minimal context on the task and ask them to follow it. If they'd be confused, Claude will be too.

- Be specific about the desired output format and constraints.
- Provide instructions as sequential steps using numbered lists or bullet points when the order or completeness of steps matters.

Example: Creating an analytics dashboard

**Less effective:**
```text
Create an analytics dashboard
```

**More effective:**
```text
Create an analytics dashboard. Include as many relevant features and interactions as
possible. Go beyond the basics to create a fully-featured implementation.
```

### Add context to improve performance

Providing context or motivation behind your instructions, such as explaining to Claude why such behavior is important, can help Claude better understand your goals and deliver more targeted responses.

Example: Formatting preferences

**Less effective:**
```text
NEVER use ellipses
```

**More effective:**
```text
Your response will be read aloud by a text-to-speech engine, so never use ellipses since
the text-to-speech engine will not know how to pronounce them.
```

Claude is smart enough to generalize from the explanation.

### Use examples effectively

Examples are one of the most reliable ways to steer Claude's output format, tone, and structure. A few well-crafted examples (known as few-shot or multishot prompting) can dramatically improve accuracy and consistency.

When adding examples, make them:
- **Relevant:** Mirror your actual use case closely.
- **Diverse:** Cover edge cases and vary enough that Claude doesn't pick up unintended patterns.
- **Structured:** Wrap examples in `<example>` tags (multiple examples in `<examples>` tags) so Claude can distinguish them from instructions.

> Tip: Include 3–5 examples for best results. You can also ask Claude to evaluate your examples for relevance and diversity, or to generate additional ones based on your initial set.

### Structure prompts with XML tags

XML tags help Claude parse complex prompts unambiguously, especially when your prompt mixes instructions, context, examples, and variable inputs. Wrapping each type of content in its own tag (e.g. `<instructions>`, `<context>`, `<input>`) reduces misinterpretation.

Best practices:
- Use consistent, descriptive tag names across your prompts.
- Nest tags when content has a natural hierarchy (documents inside `<documents>`, each inside `<document index="n">`).

### Give Claude a role

Setting a role in the system prompt focuses Claude's behavior and tone for your use case. Even a single sentence makes a difference:

```python
import anthropic

client = anthropic.Anthropic()

message = client.messages.create(
    model="claude-opus-4-8",
    max_tokens=1024,
    system="You are a helpful coding assistant specializing in Python.",
    messages=[
        {"role": "user", "content": "How do I sort a list of dictionaries by key?"}
    ],
)
print(message.content)
```

### Long context prompting

When working with large documents or data-rich inputs (20k+ tokens), structure your prompt carefully to get the best results:

- **Put longform data at the top:** Place your long documents and inputs near the top of your prompt, above your query, instructions, and examples. This can significantly improve performance across all models.

  > Note: Queries at the end can improve response quality by up to 30% in tests, especially with complex, multi-document inputs.

- **Structure document content and metadata with XML tags:** When using multiple documents, wrap each document in `<document>` tags with `<document_content>` and `<source>` (and other metadata) subtags for clarity.

  Example multi-document structure:

  ```xml
  <documents>
    <document index="1">
      <source>annual_report_2023.pdf</source>
      <document_content>
        {{ANNUAL_REPORT}}
      </document_content>
    </document>
    <document index="2">
      <source>competitor_analysis_q2.xlsx</source>
      <document_content>
        {{COMPETITOR_ANALYSIS}}
      </document_content>
    </document>
  </documents>

  Analyze the annual report and competitor analysis. Identify strategic advantages and recommend Q3 focus areas.
  ```

- **Ground responses in quotes:** For long document tasks, ask Claude to quote relevant parts of the documents first before carrying out its task. This helps Claude cut through the noise of the rest of the document's contents.

  Example quote extraction:

  ```xml
  You are an AI physician's assistant. Your task is to help doctors diagnose possible patient illnesses.

  <documents>
    <document index="1">
      <source>patient_symptoms.txt</source>
      <document_content>
        {{PATIENT_SYMPTOMS}}
      </document_content>
    </document>
    <document index="2">
      <source>patient_records.txt</source>
      <document_content>
        {{PATIENT_RECORDS}}
      </document_content>
    </document>
    <document index="3">
      <source>patient01_appt_history.txt</source>
      <document_content>
        {{PATIENT01_APPOINTMENT_HISTORY}}
      </document_content>
    </document>
  </documents>

  Find quotes from the patient records and appointment history that are relevant to diagnosing the patient's reported symptoms. Place these in <quotes> tags. Then, based on these quotes, list all information that would help the doctor diagnose the patient's symptoms. Place your diagnostic information in <info> tags.
  ```

### Model self-knowledge

If you would like Claude to identify itself correctly in your application or use specific API strings:

```text
The assistant is Claude, created by Anthropic. The current model is Claude Opus 4.8.
```

For LLM-powered apps that need to specify model strings:

```text
When an LLM is needed, please default to Claude Opus 4.8 unless the user requests
otherwise. The exact model string for Claude Opus 4.8 is claude-opus-4-8.
```

## Output and formatting

### Communication style and verbosity

Claude's latest models have a more concise and natural communication style compared to previous models:

- **More direct and grounded:** Provides fact-based progress reports rather than self-celebratory updates
- **More conversational:** Slightly more fluent and colloquial, less machine-like
- **Less verbose:** May skip detailed summaries for efficiency unless prompted otherwise

This means Claude may skip verbal summaries after tool calls, jumping directly to the next action. If you prefer more visibility into its reasoning:

```text
After completing a task that involves tool use, provide a quick summary of the work you've done.
```

### Control the format of responses

There are a few particularly effective ways to steer output formatting:

1. **Tell Claude what to do instead of what not to do**

   - Instead of: "Do not use markdown in your response"
   - Try: "Your response should be composed of smoothly flowing prose paragraphs."

2. **Use XML format indicators**

   - Try: "Write the prose sections of your response in \<smoothly_flowing_prose_paragraphs\> tags."

3. **Match your prompt style to the desired output**

   The formatting style used in your prompt may influence Claude's response style. If you are still experiencing steerability issues with output formatting, try matching your prompt style to your desired output style as closely as possible. For example, removing markdown from your prompt can reduce the volume of markdown in the output.

4. **Use detailed prompts for specific formatting preferences**

   For more control over markdown and formatting usage, provide explicit guidance:

```text
<avoid_excessive_markdown_and_bullet_points>
When writing reports, documents, technical explanations, analyses, or any long-form
content, write in clear, flowing prose using complete paragraphs and sentences. Use
standard paragraph breaks for organization and reserve markdown primarily for `inline
code`, code blocks (```...```), and simple headings (###, and ###). Avoid using **bold**
and *italics*.

DO NOT use ordered lists (1. ...) or unordered lists (*) unless : a) you're presenting
truly discrete items where a list format is the best option, or b) the user explicitly
requests a list or ranking

Instead of listing items with bullets or numbers, incorporate them naturally into
sentences. This guidance applies especially to technical writing. Using prose instead of
excessive formatting will improve user satisfaction. NEVER output a series of overly
short bullet points.

Your goal is readable, flowing text that guides the reader naturally through ideas
rather than fragmenting information into isolated points.
</avoid_excessive_markdown_and_bullet_points>
```

### LaTeX output

Claude's latest models default to LaTeX for mathematical expressions, equations, and technical explanations. If you prefer plain text, add the following instructions to your prompt:

```text
Format your response in plain text only. Do not use LaTeX, MathJax, or any markup
notation such as \( \), $, or \frac{}{}. Write all math expressions using standard text
characters (e.g., "/" for division, "*" for multiplication, and "^" for exponents).
```

### Document creation

Claude's latest models excel at creating presentations, animations, and visual documents with impressive creative flair and strong instruction following. The models produce polished, usable output on the first try in most cases.

For best results with document creation:

```text
Create a professional presentation on [topic]. Include thoughtful design elements,
visual hierarchy, and engaging animations where appropriate.
```

### Migrating away from prefilled responses

Starting with Claude 4.6 models and Claude Mythos Preview, prefilled responses on the last assistant turn are no longer supported. Requests with prefilled assistant messages to these models return a 400 error. Model intelligence and instruction following have advanced such that most use cases of prefill no longer require it. Earlier models continue to support prefills, and adding assistant messages elsewhere in the conversation is not affected.

Here are common prefill scenarios and how to migrate away from them:

**Controlling output formatting**

Prefills have been used to force specific output formats like JSON/YAML, classification, and similar patterns where the prefill constrains Claude to a particular structure.

Migration: The Structured Outputs feature is designed specifically to constrain Claude's responses to follow a given schema. Try simply asking the model to conform to your output structure first, as newer models can reliably match complex schemas when told to, especially if implemented with retries. For classification tasks, use either tools with an enum field containing your valid labels or structured outputs.

**Eliminating preambles**

Prefills like `Here is the requested summary:\n` were used to skip introductory text.

Migration: Use direct instructions in the system prompt: "Respond directly without preamble. Do not start with phrases like 'Here is...', 'Based on...', etc." Alternatively, direct the model to output within XML tags, use structured outputs, or use tool calling. If the occasional preamble slips through, strip it in post-processing.

**Avoiding bad refusals**

Prefills were used to steer around unnecessary refusals.

Migration: Claude is much better at appropriate refusals now. Clear prompting within the `user` message without prefill should be sufficient.

**Continuations**

Prefills were used to continue partial completions, resume interrupted responses, or pick up where a previous generation left off.

Migration: Move the continuation to the user message, and include the final text from the interrupted response: "Your previous response was interrupted and ended with \`[previous_response]\`. Continue from where you left off." If this is part of error-handling or incomplete-response-handling and there is no UX penalty, retry the request.

**Context hydration and role consistency**

Prefills were used to periodically ensure refreshed or injected context.

Migration: For very long conversations, inject what were previously prefilled-assistant reminders into the user turn. If context hydration is part of a more complex agentic system, consider hydrating via tools (expose or encourage use of tools containing context based on heuristics such as number of turns) or during context compaction.

## Tool use

### Tool usage

Claude's latest models are trained for precise instruction following and benefit from explicit direction to use specific tools. If you say "can you suggest some changes," Claude will sometimes provide suggestions rather than implementing them, even if making changes might be what you intended.

For Claude to take action, be more explicit:

**Less effective (Claude will only suggest):**
```text
Can you suggest some changes to improve this function?
```

**More effective (Claude will make the changes):**
```text
Change this function to improve its performance.
```

Or:
```text
Make these edits to the authentication flow.
```

To make Claude more proactive about taking action by default, you can add this to your system prompt:

```text
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is
unclear, infer the most useful likely action and proceed, using tools to discover any
missing details instead of guessing. Try to infer the user's intent about whether a tool
call (e.g., file edit or read) is intended or not, and act accordingly.
</default_to_action>
```

On the other hand, if you want the model to be more hesitant by default, less prone to jumping straight into implementations, and only take action if requested, you can steer this behavior with a prompt like the below:

```text
<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed to make
changes. When the user's intent is ambiguous, default to providing information, doing
research, and providing recommendations rather than taking action. Only proceed with
edits, modifications, or implementations when the user explicitly requests them.
</do_not_act_before_instructions>
```

Claude Opus 4.5 and Claude Opus 4.6 are also more responsive to the system prompt than previous models. If your prompts were designed to reduce undertriggering on tools or skills, these models may now overtrigger. The fix is to dial back any aggressive language. Where you might have said "CRITICAL: You MUST use this tool when...", you can use more normal prompting like "Use this tool when...".

### Optimize parallel tool calling

Claude's latest models excel at parallel tool execution. These models will:

- Run multiple speculative searches during research
- Read several files at once to build context faster
- Execute bash commands in parallel (which can even bottleneck system performance)

This behavior is easily steerable. While the model has a high success rate in parallel tool calling without prompting, you can boost this to ~100% or adjust the aggression level:

```text
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool
calls, make all of the independent tool calls in parallel. Prioritize calling tools
simultaneously whenever the actions can be done in parallel rather than sequentially.
For example, when reading 3 files, run 3 tool calls in parallel to read all 3 files into
context at the same time. Maximize use of parallel tool calls where possible to increase
speed and efficiency. However, if some tool calls depend on previous calls to inform
dependent values like the parameters, do NOT call these tools in parallel and instead
call them sequentially. Never use placeholders or guess missing parameters in tool
calls.
</use_parallel_tool_calls>
```

```text
Execute operations sequentially with brief pauses between each step to ensure stability.
```

## Thinking and reasoning

### Overthinking and excessive thoroughness

Claude Opus 4.6 does significantly more upfront exploration than previous models, especially at higher `effort` settings. This initial work often helps to optimize the final results, but the model may gather extensive context or pursue multiple threads of research without being prompted. If your prompts previously encouraged the model to be more thorough, you should tune that guidance for Claude Opus 4.6:

- **Replace blanket defaults with more targeted instructions.** Instead of "Default to using [tool]," add guidance like "Use [tool] when it would enhance your understanding of the problem."
- **Remove over-prompting.** Tools that undertriggered in previous models are likely to trigger appropriately now. Instructions like "If in doubt, use [tool]" will cause overtriggering.
- **Use effort as a fallback.** If Claude continues to be overly aggressive, use a lower setting for `effort`.

In some cases, Claude Opus 4.6 may think extensively, which can inflate thinking tokens and slow down responses. If this behavior is undesirable, you can add explicit instructions to constrain its reasoning, or you can lower the `effort` setting to reduce overall thinking and token usage.

```text
When you're deciding how to approach a problem, choose an approach and commit to it.
Avoid revisiting decisions unless you encounter new information that directly
contradicts your reasoning. If you're weighing two approaches, pick one and see it
through. You can always course-correct later if the chosen approach fails.
```

If you need a hard ceiling on thinking costs, extended thinking with a `budget_tokens` cap is still functional on Opus 4.6 and Sonnet 4.6 but is deprecated. Prefer lowering the effort setting or using `max_tokens` as a hard limit with adaptive thinking.

### Leverage thinking & interleaved thinking capabilities

Claude's latest models offer thinking capabilities that can be especially helpful for tasks involving reflection after tool use or complex multi-step reasoning. You can guide its initial or interleaved thinking for better results.

Claude Opus 4.6 and Claude Sonnet 4.6 use adaptive thinking (`thinking: {type: "adaptive"}`), where Claude dynamically decides when and how much to think. Claude calibrates its thinking based on two factors: the `effort` parameter and query complexity. Higher effort elicits more thinking, and more complex queries do the same. On easier queries that don't require thinking, the model responds directly. In internal evaluations, adaptive thinking reliably drives better performance than extended thinking. Consider moving to adaptive thinking to get the most intelligent responses.

Use adaptive thinking for workloads that require agentic behavior such as multi-step tool use, complex coding tasks, and long-horizon agent loops. Older models use manual thinking mode with `budget_tokens`.

You can guide Claude's thinking behavior:

```text
After receiving tool results, carefully reflect on their quality and determine optimal
next steps before proceeding. Use your thinking to plan and iterate based on this new
information, and then take the best next action.
```

The triggering behavior for adaptive thinking is promptable. If you find the model thinking more often than you'd like, which can happen with large or complex system prompts, add guidance to steer it:

```text
Extended thinking adds latency and should only be used when it will meaningfully improve
answer quality - typically for problems that require multi-step reasoning. When in
doubt, respond directly.
```

If you are migrating from extended thinking with `budget_tokens`, replace your thinking configuration and move budget control to `effort`:

**Before (extended thinking, older models):**

```python
client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=64000,
    thinking={"type": "enabled", "budget_tokens": 32000},
    messages=[{"role": "user", "content": "..."}],
)
```

**After (adaptive thinking):**

```python
client.messages.create(
    model="claude-opus-4-8",
    max_tokens=64000,
    thinking={"type": "adaptive"},
    output_config={"effort": "high"},  # or "max", "xhigh", "medium", "low"
    messages=[{"role": "user", "content": "..."}],
)
```

If you are not using extended thinking, no changes are required. Thinking is off by default when you omit the `thinking` parameter.

- **Prefer general instructions over prescriptive steps.** A prompt like "think thoroughly" often produces better reasoning than a hand-written step-by-step plan. Claude's reasoning frequently exceeds what a human would prescribe.
- **Multishot examples work with thinking.** Use `<thinking>` tags inside your few-shot examples to show Claude the reasoning pattern. It will generalize that style to its own extended thinking blocks.
- **Manual CoT as a fallback.** When thinking is off, you can still encourage step-by-step reasoning by asking Claude to think through the problem. Use structured tags like `<thinking>` and `<answer>` to cleanly separate reasoning from the final output.
- **Ask Claude to self-check.** Append something like "Before you finish, verify your answer against [test criteria]." This catches errors reliably, especially for coding and math.

> Note: When extended thinking is disabled, Claude Opus 4.5 is particularly sensitive to the word "think" and its variants. Consider using alternatives like "consider," "evaluate," or "reason through" in those cases.

## Agentic systems

### Long-horizon reasoning and state tracking

Claude's latest models excel at long-horizon reasoning tasks with exceptional state tracking capabilities. Claude maintains orientation across extended sessions by focusing on incremental progress, making steady advances on a few things at a time rather than attempting everything at once. This capability especially emerges over multiple context windows or task iterations, where Claude can work on a complex task, save the state, and continue with a fresh context window.

#### Context awareness and multi-window workflows

Claude 4.6 and Claude 4.5 models feature context awareness, enabling the model to track its remaining context window (i.e. "token budget") throughout a conversation. This enables Claude to execute tasks and manage context more effectively by understanding how much space it has to work.

**Managing context limits:**

If you are using Claude in an agent harness that compacts context or allows saving context to external files (like in Claude Code), consider adding this information to your prompt so Claude can behave accordingly. Otherwise, Claude may sometimes naturally try to wrap up work as it approaches the context limit. Below is an example prompt:

```text
Your context window will be automatically compacted as it approaches its limit, allowing
you to continue working indefinitely from where you left off. Therefore, do not stop
tasks early due to token budget concerns. As you approach your token budget limit, save
your current progress and state to memory before the context window refreshes. Always be
as persistent and autonomous as possible and complete tasks fully, even if the end of
your budget is approaching. Never artificially stop any task early regardless of the
context remaining.
```

The memory tool pairs naturally with context awareness for seamless context transitions.

#### Multi-context window workflows

For tasks spanning multiple context windows:

1. **Use a different prompt for the very first context window:** Use the first context window to set up a framework (write tests, create setup scripts), then use future context windows to iterate on a todo-list.

2. **Have the model write tests in a structured format:** Ask Claude to create tests before starting work and keep track of them in a structured format (e.g., `tests.json`). This leads to better long-term ability to iterate. Remind Claude of the importance of tests: "It is unacceptable to remove or edit tests because this could lead to missing or buggy functionality."

3. **Set up quality of life tools:** Encourage Claude to create setup scripts (e.g., `init.sh`) to gracefully start servers, run test suites, and linters. This prevents repeated work when continuing from a fresh context window.

4. **Starting fresh vs compacting:** When a context window is cleared, consider starting with a brand new context window rather than using compaction. Claude's latest models are extremely effective at discovering state from the local filesystem. In some cases, you may want to take advantage of this over compaction. Be prescriptive about how it should start:
   - "Call pwd; you can only read and write files in this directory."
   - "Review progress.txt, tests.json, and the git logs."
   - "Manually run through a fundamental integration test before moving on to implementing new features."

5. **Provide verification tools:** As the length of autonomous tasks grows, Claude needs to verify correctness without continuous human feedback. Tools like Playwright MCP server or computer use capabilities for testing UIs are helpful.

6. **Encourage complete usage of context:** Prompt Claude to efficiently complete components before moving on:

```text
This is a very long task, so it may be beneficial to plan out your work clearly. It's
encouraged to spend your entire output context working on the task - just make sure you
don't run out of context with significant uncommitted work. Continue working
systematically until you have completed this task.
```

#### State management best practices

- **Use structured formats for state data:** When tracking structured information (like test results or task status), use JSON or other structured formats to help Claude understand schema requirements
- **Use unstructured text for progress notes:** Freeform progress notes work well for tracking general progress and context
- **Use git for state tracking:** Git provides a log of what's been done and checkpoints that can be restored. Claude's latest models perform especially well in using git to track state across multiple sessions.
- **Emphasize incremental progress:** Explicitly ask Claude to keep track of its progress and focus on incremental work

Example: State tracking

```json
// Structured state file (tests.json)
{
  "tests": [
    { "id": 1, "name": "authentication_flow", "status": "passing" },
    { "id": 2, "name": "user_management", "status": "failing" },
    { "id": 3, "name": "api_endpoints", "status": "not_started" }
  ],
  "total": 200,
  "passing": 150,
  "failing": 25,
  "not_started": 25
}
```

```text
// Progress notes (progress.txt)
Session 3 progress:
- Fixed authentication token validation
- Updated user model to handle edge cases
- Next: investigate user_management test failures (test #2)
- Note: Do not remove tests as this could lead to missing functionality
```

### Balancing autonomy and safety

Without guidance, Claude Opus 4.6 may take actions that are difficult to reverse or affect shared systems, such as deleting files, force-pushing, or posting to external services. If you want Claude Opus 4.6 to confirm before taking potentially risky actions, add guidance to your prompt:

```text
Consider the reversibility and potential impact of your actions. You are encouraged to
take local, reversible actions like editing files or running tests, but for actions that
are hard to reverse, affect shared systems, or could be destructive, ask the user before
proceeding.

Examples of actions that warrant confirmation:
- Destructive operations: deleting files or branches, dropping database tables, rm -rf
- Hard to reverse operations: git push --force, git reset --hard, amending published commits
- Operations visible to others: pushing code, commenting on PRs/issues, sending
messages, modifying shared infrastructure

When encountering obstacles, do not use destructive actions as a shortcut. For example,
don't bypass safety checks (e.g. --no-verify) or discard unfamiliar files that may be
in-progress work.
```

### Research and information gathering

Claude's latest models demonstrate exceptional agentic search capabilities and can find and synthesize information from multiple sources effectively. For optimal research results:

1. **Provide clear success criteria:** Define what constitutes a successful answer to your research question

2. **Encourage source verification:** Ask Claude to verify information across multiple sources

3. **For complex research tasks, use a structured approach:**

```text
Search for this information in a structured way. As you gather data, develop several
competing hypotheses. Track your confidence levels in your progress notes to improve
calibration. Regularly self-critique your approach and plan. Update a hypothesis tree or
research notes file to persist information and provide transparency. Break down this
complex research task systematically.
```

This structured approach allows Claude to find and synthesize virtually any piece of information and iteratively critique its findings, no matter the size of the corpus.

### Subagent orchestration

Claude's latest models demonstrate significantly improved native subagent orchestration capabilities. These models can recognize when tasks would benefit from delegating work to specialized subagents and do so proactively without requiring explicit instruction.

To take advantage of this behavior:

1. **Ensure well-defined subagent tools:** Have subagent tools available and described in tool definitions
2. **Let Claude orchestrate naturally:** Claude will delegate appropriately without explicit instruction
3. **Watch for overuse:** Claude Opus 4.6 has a strong predilection for subagents and may spawn them in situations where a simpler, direct approach would suffice. For example, the model may spawn subagents for code exploration when a direct grep call is faster and sufficient.

If you're seeing excessive subagent use, add explicit guidance about when subagents are and aren't warranted:

```text
Use subagents when tasks can run in parallel, require isolated context, or involve
independent workstreams that don't need to share state. For simple tasks, sequential
operations, single-file edits, or tasks where you need to maintain context across steps,
work directly rather than delegating.
```

### Chain complex prompts

With adaptive thinking and subagent orchestration, Claude handles most multi-step reasoning internally. Explicit prompt chaining (breaking a task into sequential API calls) is still useful when you need to inspect intermediate outputs or enforce a specific pipeline structure.

The most common chaining pattern is **self-correction:** generate a draft → have Claude review it against criteria → have Claude refine based on the review. Each step is a separate API call so you can log, evaluate, or branch at any point.

### Reduce file creation in agentic coding

Claude's latest models may sometimes create new files for testing and iteration purposes, particularly when working with code. This approach allows Claude to use files, especially python scripts, as a 'temporary scratchpad' before saving its final output. Using temporary files can improve outcomes particularly for agentic coding use cases.

If you'd prefer to minimize net new file creation, you can instruct Claude to clean up after itself:

```text
If you create any temporary new files, scripts, or helper files for iteration, clean up
these files by removing them at the end of the task.
```

### Overeagerness

Claude Opus 4.5 and Claude Opus 4.6 have a tendency to overengineer by creating extra files, adding unnecessary abstractions, or building in flexibility that wasn't requested. If you're seeing this undesired behavior, add specific guidance to keep solutions minimal.

For example:

```text
Avoid over-engineering. Only make changes that are directly requested or clearly
necessary. Keep solutions simple and focused:

- Scope: Don't add features, refactor code, or make "improvements" beyond what was
asked. A bug fix doesn't need surrounding code cleaned up. A simple feature doesn't need
extra configurability.

- Documentation: Don't add docstrings, comments, or type annotations to code you didn't
change. Only add comments where the logic isn't self-evident.

- Defensive coding: Don't add error handling, fallbacks, or validation for scenarios
that can't happen. Trust internal code and framework guarantees. Only validate at system
boundaries (user input, external APIs).

- Abstractions: Don't create helpers, utilities, or abstractions for one-time
operations. Don't design for hypothetical future requirements. The right amount of
complexity is the minimum needed for the current task.
```

### Avoid focusing on passing tests and hard-coding

Claude can sometimes focus too heavily on making tests pass at the expense of more general solutions, or may use workarounds like helper scripts for complex refactoring instead of using standard tools directly. To prevent this behavior and ensure robust, generalizable solutions:

```text
Please write a high-quality, general-purpose solution using the standard tools
available. Do not create helper scripts or workarounds to accomplish the task more
efficiently. Implement a solution that works correctly for all valid inputs, not just
the test cases. Do not hard-code values or create solutions that only work for specific
test inputs. Instead, implement the actual logic that solves the problem generally.

Focus on understanding the problem requirements and implementing the correct algorithm.
Tests are there to verify correctness, not to define the solution. Provide a principled
implementation that follows best practices and software design principles.

If the task is unreasonable or infeasible, or if any of the tests are incorrect, please
inform me rather than working around them. The solution should be robust, maintainable,
and extendable.
```

### Minimizing hallucinations in agentic coding

Claude's latest models are less prone to hallucinations and give more accurate, grounded, intelligent answers based on the code. To encourage this behavior even more and minimize hallucinations:

```text
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file,
you MUST read the file before answering. Make sure to investigate and read relevant
files BEFORE answering questions about the codebase. Never make any claims about code
before investigating unless you are certain of the correct answer - give grounded and
hallucination-free answers.
</investigate_before_answering>
```

## Capability-specific tips

### Improved vision capabilities

Claude Opus 4.5 and Claude Opus 4.6 have improved vision capabilities compared to previous Claude models. They perform better on image processing and data extraction tasks, particularly when there are multiple images present in context. These improvements carry over to computer use, where the models can more reliably interpret screenshots and UI elements. You can also use these models to analyze videos by breaking them up into frames.

One technique that has proven effective to further boost performance is to give Claude a crop tool or skill. Testing has shown consistent uplift on image evaluations when Claude is able to "zoom" in on relevant regions of an image. Anthropic has created a cookbook for the crop tool.

### Frontend design

Claude Opus 4.5 and Claude Opus 4.6 excel at building complex, real-world web applications with strong frontend design. However, without guidance, models can default to generic patterns that create what users call the "AI slop" aesthetic. To create distinctive, creative frontends that surprise and delight:

> Tip: For a detailed guide on improving frontend design, see the blog post on improving frontend design through skills.

Here's a system prompt snippet you can use to encourage better frontend design:

```text
<frontend_aesthetics>
You tend to converge toward generic, "on distribution" outputs. In frontend design, this
creates what users call the "AI slop" aesthetic. Avoid this: make creative, distinctive
frontends that surprise and delight.

Focus on:
- Typography: Choose fonts that are beautiful, unique, and interesting. Avoid generic
fonts like Arial and Inter; opt instead for distinctive choices that elevate the
frontend's aesthetics.
- Color & Theme: Commit to a cohesive aesthetic. Use CSS variables for consistency.
Dominant colors with sharp accents outperform timid, evenly-distributed palettes. Draw
from IDE themes and cultural aesthetics for inspiration.
- Motion: Use animations for effects and micro-interactions. Prioritize CSS-only
solutions for HTML. Use Motion library for React when available. Focus on high-impact
moments: one well-orchestrated page load with staggered reveals (animation-delay)
creates more delight than scattered micro-interactions.
- Backgrounds: Create atmosphere and depth rather than defaulting to solid colors. Layer
CSS gradients, use geometric patterns, or add contextual effects that match the overall
aesthetic.

Avoid generic AI-generated aesthetics:
- Overused font families (Inter, Roboto, Arial, system fonts)
- Clichéd color schemes (particularly purple gradients on white backgrounds)
- Predictable layouts and component patterns
- Cookie-cutter design that lacks context-specific character

Interpret creatively and make unexpected choices that feel genuinely designed for the
context. Vary between light and dark themes, different fonts, different aesthetics. You
still tend to converge on common choices (Space Grotesk, for example) across
generations. Avoid this: it is critical that you think outside the box!
</frontend_aesthetics>
```

You can also refer to the full skill definition in the anthropics/claude-code repository (plugins/frontend-design).

## Migration considerations

When migrating to Claude 4.6 models from earlier generations:

1. **Be specific about desired behavior:** Consider describing exactly what you'd like to see in the output.

2. **Frame your instructions with modifiers:** Adding modifiers that encourage Claude to increase the quality and detail of its output can help better shape Claude's performance. For example, instead of "Create an analytics dashboard", use "Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation."

3. **Request specific features explicitly:** Animations and interactive elements should be requested explicitly when desired.

4. **Update thinking configuration:** Claude 4.6 models use adaptive thinking (`thinking: {type: "adaptive"}`) instead of manual thinking with `budget_tokens`. Use the effort parameter to control thinking depth.

5. **Migrate away from prefilled responses:** Prefilled responses on the last assistant turn are no longer supported starting with Claude 4.6 models. See "Migrating away from prefilled responses" for detailed guidance on alternatives.

6. **Tune anti-laziness prompting:** If your prompts previously encouraged the model to be more thorough or use tools more aggressively, dial back that guidance. Claude 4.6 models are significantly more proactive and may overtrigger on instructions that were needed for previous models.

For detailed migration steps, see the Migration guide.

### Migrating from Claude Sonnet 4.5 to Claude Sonnet 4.6

See "Migrating from Sonnet 4.5" in the migration guide, which covers the effort default change and both extended-thinking migration paths.

---
---

# Part 2 — Prompting Claude Fable 5(模型专属子页)

Behavioral differences and prompting patterns for Claude Fable 5 and Claude Mythos 5, covering effort, instruction following, long runs, memory, and scaffolding changes.

---

This guide covers the prompting and scaffolding patterns specific to Claude Fable 5 and Claude Mythos 5. For the model's capabilities, API changes, pricing, and availability, see "Introducing Claude Fable 5 and Claude Mythos 5". For techniques that apply across all current Claude models, see Part 1.

Claude Fable 5 takes on problems that were previously too complex, long-running, or ambiguous for prior models, and is particularly effective at end-to-end work that takes a person hours, days, or weeks to complete. The teams seeing the best outcomes apply Claude Fable 5 to their hardest unsolved problems; testing it only on simpler workloads tends to undersell its capability range. It also performs reliably on more straightforward tasks.

Claude Fable 5 has several behavioral differences from Claude Opus 4.8 that may require prompt or scaffolding updates. Capability improvements at this level are also a good prompt to re-evaluate which instructions, tools, and guardrails are still needed. The patterns below cover the behaviors that most often require tuning.

> Note: For API parameter changes specific to Claude Fable 5 and Claude Mythos 5 (adaptive thinking only, summarized-only thinking output, no extended thinking budgets, the `refusal` stop reason and fallback handling), see "Introducing Claude Fable 5 and Claude Mythos 5".
>
> Claude Fable 5 runs safety classifiers that target offensive cybersecurity techniques (such as building exploits, malware, or attack tooling), biology and life sciences content (such as lab methods or molecular mechanisms), and extraction of the model's summarized thinking. Benign cybersecurity work and beneficial life sciences tasks may also trigger these safeguards. To re-route declined requests automatically, configure server-side or client-side fallback to Claude Opus 4.8.

## Capability improvements

Compared with Claude Opus 4.8, Claude Fable 5 shows improvement in:

- **Long-horizon autonomy.** Claude Fable 5 sustains productive output over extended periods, completing multi-day, goal-directed runs with strong instruction retention across long, complex tasks.
- **First-shot correctness on complex, well-specified problems.** Early testers reported single-pass implementations of systems that previously took days of iteration.
- **Vision.** Claude Fable 5 interprets dense technical images, web applications, and detailed screenshots with substantially higher accuracy, often while using fewer output tokens, and is trained to use bash and crop tools to handle flipped, blurry, or noisy images.
- **Enterprise workflows.** Claude Fable 5 follows instructions, stays in scope, and produces professional-grade output on financial analysis, spreadsheets, slides, and documents.
- **Code review and debugging.** Bug-finding recall (outside the cybersecurity domains the safety classifiers cover) is noticeably higher than Claude Opus 4.8, including search across codebases and repository history.
- **Navigating ambiguity.** Claude Fable 5 performs well when given complex, multi-threaded requests and asked to determine next steps.
- **Delegation and collaboration.** Claude Fable 5 is significantly more dependable at dispatching and sustaining parallel subagents, and reliably manages ongoing communication with long-running subagents and peer agents.

Beyond these specific improvements, Claude Fable 5 is generally more capable than prior models on almost all tasks. Claude Fable 5 is not intended for offensive cybersecurity or biology and life sciences work; requests in those domains can return `stop_reason: "refusal"`.

## Longer turns by default

Individual requests on hard tasks can run for many minutes at higher effort settings, especially when the task requires gathering context, building, and self-verifying, and autonomous runs can extend for hours. This is one of the largest shifts teams encounter when adjusting to Claude Fable 5. Adjust client timeouts, streaming, and user-facing progress indicators before migrating, and consider restructuring harnesses to check on runs asynchronously, for example through scheduled jobs, rather than blocking. To keep Claude Fable 5 from overplanning when a task is ambiguous:

```text
When you have enough information to act, act. Do not re-derive facts already established
in the conversation, re-litigate a decision the user has already made, or narrate
options you will not pursue in user-facing messages. If you are weighing a choice, give
a recommendation, not an exhaustive survey. This does not apply to thinking blocks.
```

## Consider all effort levels

Effort is the primary control for the trade-off between intelligence, latency, and cost on Claude Fable 5. Use `high` as the default for most tasks, with `xhigh` for the most capability-sensitive workloads and `medium` or `low` for routine work. Lower effort settings on Claude Fable 5 still perform well and often exceed `xhigh` performance on prior models. Reduce effort if a task completes but takes longer than necessary, or if you want a quicker, more interactive working style.

On routine work at higher effort, Claude Fable 5 can gather context and deliberate beyond what the task needs. At the same time, higher effort often produces excellent verification behavior, sophisticated reasoning, and the most rigorous output. To prevent unrequested tidying or refactoring at higher effort:

```text
Don't add features, refactor, or introduce abstractions beyond what the task requires. A
bug fix doesn't need surrounding cleanup and a one-shot operation usually doesn't need a
helper. Don't design for hypothetical future requirements: do the simplest thing that
works well. Avoid premature abstraction and half-finished implementations. Don't add
error handling, fallbacks, or validation for scenarios that cannot happen. Trust
internal code and framework guarantees. Only validate at system boundaries (user input,
external APIs). Don't use feature flags or backwards-compatibility shims when you can
just change the code.
```

## Strong instruction following

Instruction-following is improved enough that you can steer most behaviors with a brief instruction rather than enumerating each behavior by name. For example, when un-steered, Claude Fable 5 can elaborate beyond what the task needs, especially at higher effort settings: surveying options it won't pursue, explaining root causes at length, producing heavily-structured PR descriptions, or writing comments that narrate what the next line does. A short brevity instruction is as effective as listing each pattern:

```text
Lead with the outcome. Your first sentence after finishing should answer "what happened"
or "what did you find": the thing the user would ask for if they said "just give me the
TLDR." Supporting detail and reasoning come after. Being readable and being concise are
different things, and readability matters more.

The way to keep output short is to be selective about what you include (drop details
that don't change what the reader would do next), not to compress the writing into
fragments, abbreviations, arrow chains like A → B → fails, or jargon.
```

The same applies to checkpoint behavior in long-running workflows. To have Claude Fable 5 stop only where it genuinely needs you, there is no need to enumerate every case:

```text
Pause for the user only when the work genuinely requires them: a destructive or
irreversible action, a real scope change, or input that only they can provide. If you
hit one of these, ask and end the turn, rather than ending on a promise.
```

## Ground progress claims during long runs

On long autonomous runs, instruct Claude Fable 5 to audit progress against actual tool results. In Anthropic's testing, this nearly eliminated fabricated status reports even on tasks designed to elicit them:

```text
Before reporting progress, audit each claim against a tool result from this session.
Only report work you can point to evidence for; if something is not yet verified, say so
explicitly. Report outcomes faithfully: if tests fail, say so with the output; if a step
was skipped, say that; when something is done and verified, state it plainly without
hedging.
```

## State the boundaries

Claude Fable 5 can occasionally take unrequested actions (drafting an email when none was asked for, creating defensive git-branch backups). Define explicit constraints on what Claude Fable 5 should and should not do:

```text
When the user is describing a problem, asking a question, or thinking out loud rather
than requesting a change, the deliverable is your assessment. Report your findings and
stop. Don't apply a fix until they ask for one. Before running a command that changes
system state (restarts, deletes, config edits), check that the evidence actually
supports that specific action. A signal that pattern-matches to a known failure may have
a different cause.
```

## Parallel subagents

Claude Fable 5 dispatches parallel subagents more readily than prior models. Use subagents frequently, provide explicit guidance about when delegation is appropriate, and prefer asynchronous communication between orchestrator and subagents over blocking until each subagent returns. Long-lived subagents that keep their context across subtasks save time and cost through cache reads and avoid bottlenecking on the slowest subagent.

```text
Delegate independent subtasks to subagents and keep working while they run. Intervene
if a subagent goes off track or is missing relevant context.
```

## Construct a memory system

Claude Fable 5 performs particularly well when it can record lessons from previous runs and reference them. Provide a place to write notes, as simple as a Markdown file:

```text
Store one lesson per file with a one-line summary at the top. Record corrections and
confirmed approaches alike, including why they mattered. Don't save what the repo or
chat history already records; update an existing note rather than creating a duplicate;
delete notes that turn out to be wrong.
```

To bootstrap the memory system from existing history, have Claude Fable 5 review past sessions:

```text
Reflect on the previous sessions we've had together. Use subagents to identify core
themes and lessons, and store them in [X]. Make sure you know to reference [X] for
future use.
```

## Rare cases of early stopping

Deep into a long session, Claude Fable 5 can occasionally end a turn with a text-only statement of intent ("I'll now run X") without issuing the corresponding tool call, or pause to ask permission when it already has enough to proceed. A "continue" or "go ahead and do it end to end" suffices. To define when pausing is appropriate, pair this with the checkpoint instruction in "Strong instruction following". For autonomous pipelines, add a system reminder:

```text
You are operating autonomously. The user is not watching in real time and cannot answer
questions mid-task, so asking "Want me to…?" or "Shall I…?" will block the work. For
reversible actions that follow from the original request, proceed without asking.
Offering follow-ups after the task is done is fine; asking permission after already
discussing with the user before doing the work is not. Before ending your turn, check
your last paragraph. If it is a plan, an analysis, a question, a list of next steps, or
a promise about work you have not done ("I'll…", "let me know when…"), do that work now
with tool calls. End your turn only when the task is complete or you are blocked on
input only the user can provide.
```

## Rare cases of context-budget concern

In very long sessions, Claude Fable 5 can occasionally suggest a new session, offer to summarize and hand off, or trim its own work. This is most often triggered when the harness shows a remaining-token countdown to the model. Avoid surfacing explicit context-budget counts where possible. If the harness must show them, a reassurance helps:

```text
You have ample context remaining. Do not stop, summarize, or suggest a new session on
account of context limits. Continue the work.
```

## Give the reason, not only the request

Claude Fable 5 tends to perform better when it understands the intent behind a request: context lets it connect the task to relevant information rather than inferring intent on its own. Provide context about why you're asking, especially for long-running agents drawing on multiple workstreams:

```text
I'm working on [the larger task] for [who it's for]. They need [what the output
enables]. With that in mind: [request].
```

## Readability when communicating with the user

In extended or agentic conversations (many tool calls, large working context), Claude Fable 5 can produce text that's hard to follow: dense arrow-chain shorthand, deep implementation detail, references to thinking the user never saw, or overly technical phrasing. A communication-style addendum mitigates this:

```text
Terse shorthand is fine between tool calls (that's you thinking out loud, and brevity
there is good). Your final summary is different: it's for a reader who didn't see any of
that.

If you've been working for a while without the user watching (overnight, across many
tool calls, since they last spoke), your final message is their first look at any of it.
Write it as a re-grounding, not a continuation of your working thread: the outcome
first, then the one or two things you need from them, each explained as if new. The
vocabulary you built up while working is yours, not theirs; leave it behind unless you
re-introduce it.

When you write the summary at the end, drop the working shorthand. Write complete
sentences. Spell out terms. Don't use arrow chains, hyphen-stacked compounds, or labels
you made up earlier. When you mention files, commits, flags, or other identifiers, give
each one its own plain-language clause. Open with the outcome: one sentence on what
happened or what you found. Then the supporting detail. If you have to choose between
short and clear, choose clear.
```

## Create a send-to-user tool

When running long, asynchronous agents, give the agent a way to surface a message the user must see exactly as written, without ending its turn: a deliverable (a generated code snippet or a drafted message), a progress update with specific numbers, or a direct reply to a question the user asked mid-loop. The tool's input is the message to display; when Claude calls it, render the input directly in your UI and return a simple acknowledgement as the tool result. Tool inputs are never summarized, so the content arrives intact.

```json
{
  "name": "send_to_user",
  "description": "Display a message directly to the user. Use this for progress updates, partial results, or content the user must see exactly as written before the task finishes.",
  "input_schema": {
    "type": "object",
    "properties": {
      "message": {
        "type": "string",
        "description": "The content to display to the user."
      }
    },
    "required": ["message"]
  }
}
```

Add this tool whenever your UX depends on delivering content or direct user interactions verbatim mid-task. For agents that only narrate routine progress, the model's own summaries are typically adequate.

## Recommended scaffolding changes

- **Start at the top of your difficulty range.** Pick a task harder than what you'd assign to prior models, and have Claude Fable 5 scope it, ask clarifying questions, and execute.
- **Make self-verification explicit in long-run prompts.** Separate, fresh-context verifier subagents tend to outperform self-critique. For long-running tasks, instruct: `Establish a method for checking your own work at an interval of [X] as you build. Run this every [X interval], verifying your work with subagents against the specification.`
- **Refactor existing prompts and skills.** Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality. Review and consider removing older instructions if default performance is better. Claude Fable 5 also does a good job of updating skills on the fly based on what it learns from the task at hand.
- **Don't instruct Claude to reproduce its reasoning in the response.** Prompts, skills, or harness instructions that tell the model to echo, transcribe, or explain its internal reasoning as response text can trigger the `reasoning_extraction` refusal category on Claude Fable 5, causing elevated fallbacks to Claude Opus 4.8. Audit existing skills and system prompts for reflection or show-your-thinking instructions when migrating. If your application needs reasoning visibility, read the structured `thinking` blocks from adaptive thinking instead, and use a send-to-user tool to surface progress during long runs.
- **Create a send-to-user tool.** For long, asynchronous agents, a client-side tool delivers messages to the user verbatim without ending the turn. See "Create a send-to-user tool".

---
---

# Part 3 — Prompting Claude Opus 4.8(模型专属子页)

Behavioral differences and prompting patterns for Claude Opus 4.8, covering verbosity, effort calibration, tool use, subagents, and frontend defaults.

---

This guide covers the prompting patterns specific to Claude Opus 4.8. For the model's capabilities and API changes, see "What's new in Claude Opus 4.8". For techniques that apply across all current Claude models, see Part 1.

Claude Opus 4.8 has particular strengths in long-horizon agentic work, knowledge work, vision, and memory tasks. It performs well out of the box on existing Claude Opus 4.7 prompts. The patterns below cover the behaviors that most often require tuning.

> Note: For API parameter changes when migrating from Claude Opus 4.7 (sampling parameters, effort default, 1M context window default (200k on Microsoft Foundry), mid-conversation system messages, and refusal stop details), see the migration guide.

## Response length and verbosity

Claude Opus 4.8 calibrates response length to how complex it judges the task to be, rather than defaulting to a fixed verbosity. This usually means shorter answers on simple lookups and much longer ones on open-ended analysis.

If your product depends on a certain style or verbosity of output, you may need to tune your prompts. As an example, to decrease verbosity, you might add:

```text
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

If you see specific examples of kinds of verbosity (such as over-explaining), you can add additional instructions in your prompt to prevent them. Positive examples showing how Claude can communicate with the appropriate level of concision tend to be more effective than negative examples or instructions that tell the model what not to do.

## Calibrating effort and thinking depth

The effort parameter allows you to tune Claude's intelligence versus token spend, trading off capability for faster speed and lower costs. Start with the `xhigh` effort level for coding and agentic use cases, and use a minimum of `high` effort for most intelligence-sensitive use cases. Experiment with other effort levels to further tune token usage and intelligence:

- **`max`:** Max effort can deliver performance gains in some use cases, but may show diminishing returns from increased token usage. This setting can also sometimes be prone to overthinking. Test max effort for intelligence-demanding tasks.
- **`xhigh`:** Extra high effort is the best setting for most coding and agentic use cases.
- **`high`:** This setting balances token usage and intelligence. For most intelligence-sensitive use cases, use a minimum of `high` effort.
- **`medium`:** Good for cost-sensitive use cases that need to reduce token usage while trading off intelligence.
- **`low`:** Reserve for short, scoped tasks and latency-sensitive workloads that are not intelligence-sensitive.

Claude Opus 4.8 respects effort levels strictly, especially at the low end. At `low` and `medium`, the model scopes its work to what was asked rather than going above and beyond. This is good for latency and cost, but on moderately complex tasks running at `low` effort there is some risk of under-thinking.

If you observe shallow reasoning on complex problems, raise effort to `high` or `xhigh` rather than prompting around it. If you need to keep effort at `low` for latency, add targeted guidance:

```text
This task involves multi-step reasoning. Think carefully through the problem before responding.
```

Effort is likely to be more important for this model than for any prior Opus, so experiment with it actively when you upgrade.

On Claude Opus 4.8, thinking is off unless you explicitly set `thinking: {type: "adaptive"}`. The triggering behavior for adaptive thinking is steerable. If you find the model thinking more often than you'd like, which can happen with large or complex system prompts, add guidance to steer it. As always, measure the effect of any prompting changes on performance. Example:

```text
Thinking adds latency and should only be used when it will meaningfully improve answer
quality — typically for problems that require multi-step reasoning. When in doubt,
respond directly.
```

Conversely, if you're running hard workloads at `medium` and seeing under-thinking, the first lever is to raise effort. If you need finer control, prompt for it directly.

> Note: If you are running Claude Opus 4.8 at `max` or `xhigh` effort, set a large max output token budget so the model has room to think and act across its subagents and tool calls. Start at 64k tokens and tune from there.

## Tool use triggering

Claude Opus 4.8 has a tendency to favor reasoning over tool calls. This produces better results in most cases. However, increasing the effort setting is a useful lever to increase the level of tool usage, especially in knowledge work. `high` or `xhigh` effort settings show substantially more tool usage in agentic search and coding. For scenarios where you want more tool use, you can also adjust your prompt to explicitly instruct the model about when and how to properly use its tools. For instance, if you find that the model is not using your web search tools, clearly describe why and how it should.

## User-facing progress updates

Claude Opus 4.8 provides more regular, higher-quality updates to the user throughout long agentic traces. If you've added scaffolding to force interim status messages ("After every 3 tool calls, summarize progress"), try removing it. If you find that the length or contents of Claude Opus 4.8's user-facing updates are not well-calibrated to your use case, explicitly describe what these updates should look like in the prompt and provide examples.

## More literal instruction following

Claude Opus 4.8 interprets prompts literally and explicitly, particularly at lower effort levels. It does not silently generalize an instruction from one item to another, and it does not infer requests you didn't make. The upside of this literalism is precision and less thrash, and it generally performs better for API use cases with carefully tuned prompts, structured extraction, and pipelines where you want predictable behavior. If you need Claude to apply an instruction broadly, state the scope explicitly (for example, "Apply this formatting to every section, not just the first one").

## Tone and writing style

As with any new model, prose style on long-form writing may shift. Claude Opus 4.8 tends toward a direct, opinionated style with minimal validation-forward phrasing and sparing emoji use. If your product relies on a specific voice, re-evaluate style prompts against the new baseline.

For instance, if your product voice is warmer or more conversational, add:

```text
Use a warm, collaborative tone. Acknowledge the user's framing before answering.
```

## Controlling subagent spawning

Claude Opus 4.8 tends to spawn fewer subagents by default. However, this behavior is steerable through prompting; give Claude Opus 4.8 explicit guidance around when subagents are desirable. A toy example for a coding use case:

```text
Do not spawn a subagent for work you can complete directly in a single response (e.g.
refactoring a function you can already see).

Spawn multiple subagents in the same turn when fanning out across items or reading multiple files.
```

## Design and frontend defaults

Claude Opus 4.8 has strong design instincts, with a consistent default house style: warm cream/off-white backgrounds (~`#F4F1EA`), serif display type (Georgia, Fraunces, Playfair), italic word-accents, and a terracotta/amber accent. This reads well for editorial, hospitality, and portfolio briefs, but will feel off for dashboards, dev tools, fintech, healthcare, or enterprise apps. The default appears in slide decks as well as web UIs.

This default is persistent. Generic instructions ("don't use cream," "make it clean and minimal") tend to shift the model to a different fixed palette rather than producing variety. Two approaches work reliably:

**1. Specify a concrete alternative.** The model follows explicit specs precisely (colors, typography, layout, radii, motion — spell them out).

**2. Have the model propose options before building.** This breaks the default and gives users control. If you previously relied on `temperature` for design variety, use this approach; it produces meaningfully different directions across runs. Example prompt:

```text
Before building, propose 4 distinct visual directions tailored to this brief (each as:
bg hex / accent hex / typeface — one-line rationale). Ask the user to pick one, then
implement only that direction.
```

Additionally, Claude Opus 4.8 requires less frontend design prompting than previous models to avoid generic patterns that users call the "AI slop" aesthetic. With earlier models, Anthropic recommended a lengthier prompt snippet in the frontend-design skill. However, Claude Opus 4.8 generates distinctive, creative frontends with more minimal prompting guidance. This prompt snippet works well with the above prompting advice for variety:

```text
<frontend_aesthetics>
NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto,
Arial, system fonts), cliched color schemes (particularly purple gradients on white or
dark backgrounds), predictable layouts and component patterns, and cookie-cutter design
that lacks context-specific character. Use unique fonts, cohesive colors and themes, and
animations for effects and micro-interactions.
</frontend_aesthetics>
```

## Interactive coding products

Claude Opus 4.8's token usage and behavior can differ between autonomous, asynchronous coding agents with a single user turn and interactive, synchronous coding agents with multiple user turns. Specifically, it tends to use more tokens in interactive settings, primarily because it reasons more after user turns. This can improve long-horizon coherence, instruction following, and coding capabilities in long, interactive coding sessions, but also comes with more token usage. To maximize both performance and token efficiency in coding products, use `xhigh` or `high` effort, add autonomous features like an auto mode, and reduce the number of human interactions required from your users.

Of course, when limiting the number of required user interactions, it's important to specify the task, intent, and relevant constraints upfront in the first human turn. Providing well-specified, clear, and accurate task descriptions upfront can help maximize autonomy and intelligence while minimizing extra token usage after user turns. Because Claude Opus 4.8 is more autonomous than prior models, this usage pattern helps to maximize performance. In contrast, ambiguous or underspecified prompts conveyed progressively over multiple user turns tend to relatively reduce token efficiency and sometimes performance.

## Code review harnesses

Claude Opus 4.8 is meaningfully better at finding bugs than prior models, and has both higher recall and precision in internal evals. However, if your code-review harness was tuned for an earlier model, you may initially see lower recall. This is likely a harness effect, not a capability regression. When a review prompt says things like "only report high-severity issues," "be conservative," or "don't nitpick," Claude Opus 4.8 may follow that instruction more faithfully than earlier models did: it may investigate the code just as thoroughly, identify the bugs, and then not report findings it judges to be below your stated bar. This can show up as the model doing the same depth of investigation but converting fewer investigations into reported findings, especially on lower-severity bugs. Precision typically rises, but measured recall can fall even though the model's underlying bug-finding ability has improved.

Some recommended prompt language:

```text
Report every issue you find, including ones you are uncertain about or consider
low-severity. Do not filter for importance or confidence at this stage - a separate
verification step will do that. Your goal here is coverage: it is better to surface a
finding that later gets filtered out than to silently drop a real bug. For each finding,
include your confidence level and an estimated severity so a downstream filter can rank
them.
```

This prompt can be used without having an actual second step, but moving confidence filtering out of the finding step often helps. If your harness has a separate verification, deduplication, or ranking stage, tell the model explicitly that its job at the finding stage is coverage rather than filtering.

If you do want the model to self-filter in a single pass, be concrete about where the bar is rather than using qualitative terms like "important": for example, "report any bugs that could cause incorrect behavior, a test failure, or a misleading result; only omit nits like pure style or naming preferences."

Iterate on prompts against a subset of your evals or test cases to validate recall or F1 score gains.

## Computer use

Computer use capability works across resolutions, up to a maximum resolution of 2576px / 3.75MP. Internal computer use testing shows that sending images at 1080p provides a good balance of performance and cost.

For particularly cost-sensitive workloads, 720p or 1366×768 are lower-cost options with strong performance. Conduct your own testing to find the ideal settings for your use case; experimenting with effort settings can also help tune the model's behavior.
