#!/bin/bash
# ---
# execute-prp.sh (v15 - Tool-Calling Fix)
#
# Description:
#   Prepares the full context and provides the user with the correct
#   command to launch the gemini-cli.
#
# Changes in v15:
#   - Radically updated the EXECUTE_PRP_PROMPT.
#   - Instead of asking the AI to format text, it now explicitly instructs
#     the AI to use its built-in file system and shell tools. This is the
#     key to making the CLI execute actions instead of just printing text.
# ---

# 1. Validate Input & Environment
if ! command -v gemini &> /dev/null; then
    echo "Error: gemini-cli is not installed or not in your PATH."
    echo "Please install it via npm: npm install -g @google/generative-ai-cli"
    exit 1
fi

if [ -z "$1" ]; then
  echo "Error: No PRP file specified."
  exit 1
fi

PRP_FILE_PATH=$1
if [ ! -f "$PRP_FILE_PATH" ]; then
  echo "Error: PRP file '$PRP_FILE_PATH' not found."
  exit 1
fi

# 2. Define the Execution Prompt
# This prompt instructs the AI to use its available tools to perform actions,
# rather than just generating formatted text. This is the correct way to
# make the gemini-cli execute file modifications and commands.
EXECUTE_PRP_PROMPT=$(cat <<'END_PROMPT'
You are an expert-level AI software engineer. Your task is to implement the feature described in the provided Product Requirements Prompt (PRP).

You have access to a set of tools to modify the local filesystem and execute commands. Analyze the PRP and generate the sequence of tool calls necessary to implement the feature.

**IMPORTANT RULES:**
1.  Your primary goal is to use the available tools to achieve the objectives in the PRP.
2.  Do NOT add any conversational text, explanations, or summaries.
3.  Your entire output should consist only of the necessary tool calls to complete the implementation.

Begin implementing the plan from the PRP now.
END_PROMPT
)

# 3. Prepare the Full Prompt and Save to a Local File
PRP_CONTENT=$(cat "$PRP_FILE_PATH")
FULL_PROMPT=$(cat <<EOF
$EXECUTE_PRP_PROMPT

---
Here is the PRP to execute:
---
$PRP_CONTENT
EOF
)

# Create a local directory for temp files and save the prompt there.
mkdir -p .gemini
TEMP_PROMPT_FILE=".gemini/temp_prompt.md"
echo "$FULL_PROMPT" > "$TEMP_PROMPT_FILE"

# 4. Provide the User with the Launch Command
echo "✅ PRP and context have been prepared."
echo "--------------------------------------------------------------------------------"
echo "The full starting prompt has been saved to a local file:"
echo "  => $TEMP_PROMPT_FILE"
echo ""
echo "To begin the interactive implementation session, run the following command in your terminal:"
echo ""
echo "   gemini --model gemini-2.0-flash --checkpointing --prompt \"@$TEMP_PROMPT_FILE\""
echo ""
echo "--------------------------------------------------------------------------------"
