#!/bin/bash

# ---
# execute-prp.sh (v11 - Standardized on gemini-cli)
#
# Description:
#   Acts as an AI agent that uses `gemini-cli` to get a plan, then
#   uses `awk` to parse and execute the plan step-by-step.
# ---

# 1. Validate Input & Environment
# --------------------------------
if ! command -v gemini &> /dev/null; then
    echo "Error: gemini-cli is not installed or not in your PATH."
    echo "Please install it via npm: npm install -g @google/generative-ai-cli"
    exit 1
fi
if ! command -v awk &> /dev/null; then
    echo "Error: awk is required. Please ensure it is installed."
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
# ------------------------------
EXECUTE_PRP_PROMPT=$(cat <<'END_PROMPT'
You are an expert-level AI software engineer. Your task is to implement the feature described in the provided Product Requirements Prompt (PRP).

You MUST respond with a sequence of executable actions. Do NOT add any conversational text, explanations, numbering, or any text that is not part of an action block. Your entire response must be a sequence of these blocks.

There are only two types of blocks you can use:

1. A shell command to be executed. The block MUST start with ```bash on its own line and end with ``` on its own line.
   ```bash
   cargo new my-project
   ```

2. A file to be created or modified. The block MUST start with a line containing ONLY `CREATE path/to/file.ext` or `MODIFY path/to/file.ext`, followed by the language fence (e.g., ```rust) on the next line, the code, and a final ``` on its own line.
   CREATE src/main.rs
   ```rust
   fn main() {}
   ```

Generate the complete sequence of these blocks to implement the feature.
END_PROMPT
)

# 3. Send PRP to Gemini and Get the Plan
# --------------------------------------
PRP_CONTENT=$(cat "$PRP_FILE_PATH")
FULL_PROMPT=$(cat <<EOF
$EXECUTE_PRP_PROMPT

Here is the PRP to execute:
---
$PRP_CONTENT
EOF
)


echo "🤖 Piping prompt to gemini-cli to generate an implementation plan..."

AI_PLAN=$(echo "$FULL_PROMPT" | gemini generate-text --model gemini-2.0-flash)

if [ -z "$AI_PLAN" ]; then
    echo "Error: Received an empty response from the gemini-cli."
    exit 1
fi

echo "✅ AI has generated the following plan:"
echo "--------------------------------------------------"
echo "$AI_PLAN"
echo "--------------------------------------------------"

# 4. Parse the Plan using AWK into structured blocks
# --------------------------------------------------
PARSED_PLAN=$(echo "$AI_PLAN" | awk '
function print_block() {
    if (type != "") {
        print type " " path;
        print content;
        print "<--BLOCK_SEPARATOR-->";
    }
    in_block = 0; type = ""; path = ""; content = "";
}
/^(CREATE|MODIFY) / { print_block(); type = $1; path = $2; getline; in_block = 1; next; }
/^```bash/ { print_block(); type = "COMMAND"; path = ""; in_block = 1; next; }
/^```/ { print_block(); next; }
{ if (in_block) {
    if (content == "") content = $0;
    else content = content "\n" $0;
  }
}
END { print_block(); }
')

# 5. Execute the Parsed Plan
# --------------------------
echo "🤖 Starting execution of the parsed plan..."

IFS=$'\n'
BLOCKS=($(echo "$PARSED_PLAN" | awk 'BEGIN{RS="<--BLOCK_SEPARATOR-->\n"} {print}'))

for block in "${BLOCKS[@]}"; do
    if [ -z "$block" ]; then
        continue
    fi

    header=$(echo "$block" | head -n 1)
    content=$(echo "$block" | tail -n +2)
    action=$(echo "$header" | awk '{print $1}')
    filepath=$(echo "$header" | awk '{print $2}')

    if [ "$action" == "COMMAND" ]; then
        echo -e "\n🔥 AI wants to execute command:"
        echo "--- Command: ---"
        echo -e "$content"
        echo "----------------"
        read -p "Proceed? [y/n] " -n 1 -r REPLY </dev/tty
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "✅ Action approved. Executing command..."
            eval "$(echo -e "$content")"
        else
            echo "❌ Action skipped by user."
        fi
    elif [ "$action" == "CREATE" ] || [ "$action" == "MODIFY" ]; then
        echo -e "\n🔥 AI wants to $action file: $filepath"
        echo "--- Code: ---"
        echo -e "$content"
        echo "---------------"
        read -p "Proceed? [y/n] " -n 1 -r REPLY </dev/tty
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$(dirname "$filepath")"
            echo -e "$content" > "$filepath"
            echo "✅ Action approved. File '$filepath' has been written."
        else
            echo "❌ Action skipped by user."
        fi
    fi
done

echo -e "\n🎉 Plan execution complete."
