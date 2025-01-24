# Node.js Style Guide

This is a collection of best practices for writing Node.js scripts.

---

## General Guidelines

1. **File Naming**: Use lowercase letters and hyphens to separate words in
   filenames (e.g., `example-script.js`).
2. **Use Strict Mode**: Always use strict mode by including `'use strict';` at
   the top of your files.
3. **Coding Standards**: Follow consistent and clean coding practices throughout
   your codebase.

## Structure and Organization

1. **Module Imports**: Prefer using `import` statements over `require` for
   importing modules. Group all import statements at the beginning of the file.

   ```javascript
   import fs from 'fs';
   import path from 'path';
   ```

2. **Function Definitions**: Define all functions before invoking them.

3. **Error Handling**: Use `try-catch` blocks for error handling and log
   meaningful error messages.

   ```javascript
   try {
     // code that may throw an error
   } catch (error) {
     console.error('Error message:', error);
     process.exit(1);
   }
   ```

4. **Environment Variables**: Access environment variables using `process.env`.

   ```javascript
   const templateDir = process.env.TEMP_TEMPLATE_DIR;
   ```

5. **File Paths**: Use `path.join` for constructing file paths.

   ```javascript
   const filePath = path.join(process.cwd(), 'filename');
   ```

## Coding Practices

1. **Consistent Indentation**: Use 2 spaces for indentation.
2. **Semicolons**: Always use semicolons.
3. **Variable Declarations**: Use `const` for constants and `let` for variables
   that will be reassigned.

   ```javascript
   const constantValue = 42;
   let variableValue = 'Hello, World!';
   ```

4. **Arrow Functions**: Prefer arrow functions for anonymous functions.

   ```javascript
   const exampleFunction = () => {
     // function body
   };
   ```

5. **Template Literals**: Use template literals for string concatenation.

   ```javascript
   const message = `Hello, ${name}!`;
   ```

## Example Template

Here is an example template that follows these guidelines:

```javascript
#!/usr/bin/env node
/* eslint-env node */

'use strict';

import fs from 'fs';
import path from 'path';

// Function definitions
const exampleFunction = (filePath) => {
  try {
    if (!fs.existsSync(filePath)) {
      throw new Error(`File not found: ${filePath}`);
    }
    const fileContent = fs.readFileSync(filePath, 'utf8');
    console.log('File content:', fileContent);
  } catch (error) {
    console.error('Error reading file:', error);
    process.exit(1);
  }
};

// Main execution
const args = process.argv.slice(2);
if (args.length < 1) {
  console.error('Usage: example-script.js <file-path>');
  process.exit(1);
}

const [filePath] = args;
exampleFunction(filePath);
```
