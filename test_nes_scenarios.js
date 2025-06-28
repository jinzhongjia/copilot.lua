// NES Test Scenarios - JavaScript
// Use this file to test Next Edit Suggestions functionality

// Scenario 1: Incomplete function - should trigger NES for completion
function calculateTotal(items) {
  // Place cursor here and wait for NES suggestions
  
}

// Scenario 2: Missing error handling - should suggest try-catch
function processData(data) {
  const result = JSON.parse(data);
  return result.value;
}

// Scenario 3: Console logging - should suggest console methods
function debugFunction() {
  console.
  // Place cursor after the dot and wait
}

// Scenario 4: Missing return statement
function getUser(id) {
  const user = fetchUserById(id);
  // NES should suggest return statement here
}

// Scenario 5: Array operations - should suggest methods
function processArray(arr) {
  const filtered = arr.
  // Place cursor after the dot for array method suggestions
}

// Scenario 6: Async/await patterns
async function fetchData() {
  // Should suggest proper async patterns
}

// Scenario 7: Object destructuring
function handleResponse(response) {
  const { 
    // NES should suggest common response properties
  } = response;
}

// Scenario 8: Import statements
// Place cursor and start typing imports
// import 

// Test Instructions:
// 1. Enable NES with <leader>cn
// 2. Place cursor at indicated positions
// 3. Wait 500ms (debounce time)
// 4. Look for gray italic ghost text
// 5. Use <C-j> to accept, <C-k> to reject, <C-g> to jump
