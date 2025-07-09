You are an expert-level AI software engineer. Your task is to implement the feature described in the provided Product Requirements Prompt (PRP).

You MUST respond with a sequence of executable actions. Do NOT add any conversational text, explanations, numbering, or any text that is not part of an action block.

Your entire response must be a sequence of these blocks. There are only two types of blocks you can use:

1. A shell command to be executed. The block MUST start with ```bash on its own line and end with ``` on its own line.
   ```bash
   cargo new my-project
   ```

2. A file to be created or modified. The block MUST start with a line containing ONLY `CREATE path/to/file.ext` or `MODIFY path/to/file.ext`, followed by the language fence (e.g., ```rust) on the next line, the code, and a final ``` on its own line.
   CREATE src/main.rs
   ```rust
   fn main() {
       println!("Hello, world!");
   }
   ```

Generate the complete sequence of these blocks to implement the feature.

---
Here is the PRP to execute:
---
# Product Requirements Prompt (PRP)
## 1. Overview
- **Feature Name:** Markdown Link Checker CLI Enhancement

- **Objective:** Enhance the existing Markdown Link Checker CLI tool to support checking links in YAML files.

- **Why:** To provide a more comprehensive link checking solution that supports both Markdown and YAML files, improving the overall quality and reliability of documentation and configuration files.

## 2. Success Criteria
_This feature will be considered complete when the following conditions are met. These must be specific and measurable._

- [ ] The code runs without errors.

- [ ] All new unit tests pass.

- [ ] The feature correctly identifies and validates links in YAML files.

- [ ] The code adheres to the project standards defined in `GEMINI.md`.

## 3. Context & Resources
_This section contains all the information needed to implement the feature correctly._

### 📚 External Documentation:
_List any URLs for libraries, APIs, or tutorials._

- **Resource:** [https://pkg.go.dev/gopkg.in/yaml.v2](https://pkg.go.dev/gopkg.in/yaml.v2)

   - **Purpose:** Go library for YAML parsing.

### 💻 Internal Codebase Patterns:
_List any existing files or code snippets from this project that should be used as a pattern or inspiration._

- **File:** `src/linkchecker/main.go`

 - **Reason:** Provides the main entry point and CLI argument parsing logic for the existing Markdown link checker.

- **File:** `src/linkchecker/parser.go`

 - **Reason:** Contains the logic for parsing Markdown files and extracting links. This will need to be adapted for YAML files.

- **File:** `src/linkchecker/validator.go`

 - **Reason:** Contains the link validation logic, which should be reusable for both Markdown and YAML files.

- **File:** `tests/linkchecker_test.go`

 - **Reason:** Provides examples of how to write unit tests for the link checker.

### ⚠️ Known Pitfalls:
_List any critical warnings, rate limits, or tricky logic to be aware of._

- The YAML parsing library might have different error handling requirements compared to the Markdown parsing.
- Ensure that the CLI flags are updated to allow specifying YAML files or automatically detect file types.
- Be mindful of the existing rate limits in the link validator.

## 4. Implementation Blueprint
_This is the step-by-step plan for building the feature._

### Proposed File Structure:
_Show the desired directory tree, highlighting new or modified files._

```
src/
└── linkchecker/
    ├── main.go       (modified)
    ├── parser.go     (modified)
    ├── validator.go  (no change)
    └── yaml_parser.go (new)
tests/
└── linkchecker_test.go (modified)
```

### Task Breakdown:
_Break the implementation into a sequence of logical tasks._

**Task 1: YAML Parser Implementation**

- Implement a new `yaml_parser.go` file that uses the `gopkg.in/yaml.v2` library to parse YAML files and extract links.
- Define a function `ParseYAML(filePath string) ([]string, error)` that takes a file path as input and returns a list of links found in the YAML file.
```go
// Pseudocode for ParseYAML function
func ParseYAML(filePath string) ([]string, error) {
    // 1. Read the YAML file
    // 2. Unmarshal the YAML content into a suitable data structure
    // 3. Traverse the data structure and extract all string values that look like URLs
    // 4. Return the list of URLs and any errors encountered
}
```

**Task 2: Update `parser.go` to Handle YAML Files**

- Modify the `parser.go` file to detect the file type (Markdown or YAML) based on the file extension.
- Update the `ParseFile(filePath string) ([]string, error)` function to call either the existing Markdown parser or the new YAML parser based on the file type.
```go
// Pseudocode for ParseFile function
func ParseFile(filePath string) ([]string, error) {
    // 1. Determine the file type based on the file extension (e.g., ".md" for Markdown, ".yaml" or ".yml" for YAML)
    // 2. If the file is Markdown, call the existing Markdown parsing logic
    // 3. If the file is YAML, call the new ParseYAML function
    // 4. Return the list of URLs and any errors encountered
}
```

**Task 3: Update `main.go` to Accept YAML Files**

- Modify the `main.go` file to allow specifying YAML files as command-line arguments.
- Update the CLI flag parsing logic to handle both Markdown and YAML file extensions.

**Task 4: Update `linkchecker_test.go`**

- Add new test cases to `linkchecker_test.go` to test the YAML parsing functionality.
- Create test YAML files with various link scenarios (valid, invalid, relative, absolute) to ensure the parser works correctly.

## 5. Validation Plan
_How we will verify the implementation is correct._

### Unit Tests:
_Describe the specific test cases that need to be created._

- `TestParseYAML_ValidLinks():` Should successfully extract all valid links from a YAML file.

- `TestParseYAML_InvalidLinks():` Should identify invalid links in a YAML file.

- `TestParseYAML_NoLinks():` Should return an empty list when no links are present in the YAML file.

- `TestParseFile_YAML():` Should correctly call the YAML parser when a YAML file is provided.

**Manual Test Command:**  
_Provide a simple command to run to see the feature in action._
```
go run src/linkchecker/main.go test.yaml
```
**Expected Output:**
```
Validating links in test.yaml
[OK] https://www.example.com
[ERROR] https://www.invalid.com - status code: 404 Not Found
```
