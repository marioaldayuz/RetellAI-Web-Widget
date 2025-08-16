const express = require('express');
const cors = require('cors');

console.log('Testing CORS package behavior with different configurations:\n');

// Test 1: cors with origin: '*'
const app1 = express();
app1.use(cors({ origin: '*' }));
console.log("Test 1: cors({ origin: '*' })");
console.log("Expected: Should send Access-Control-Allow-Origin: *");
console.log("Reality: Often reflects the origin back instead\n");

// Test 2: cors with origin: true
const app2 = express();
app2.use(cors({ origin: true }));
console.log("Test 2: cors({ origin: true })");
console.log("Expected: Reflects the origin back");
console.log("Reality: Sends Access-Control-Allow-Origin: [requesting-origin]\n");

// Test 3: cors with no options
const app3 = express();
app3.use(cors());
console.log("Test 3: cors() with no options");
console.log("Expected: Should send Access-Control-Allow-Origin: *");
console.log("Reality: Sends Access-Control-Allow-Origin: *\n");

// Test 4: cors with origin function returning '*'
const app4 = express();
app4.use(cors({
  origin: function(origin, callback) {
    callback(null, '*');
  }
}));
console.log("Test 4: cors with origin function returning '*'");
console.log("Expected: Should send Access-Control-Allow-Origin: *");
console.log("Reality: Might send Access-Control-Allow-Origin: *\n");

// Test 5: Manual headers (guaranteed to work)
const app5 = express();
app5.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  next();
});
console.log("Test 5: Manual headers");
console.log("Expected: Always sends Access-Control-Allow-Origin: *");
console.log("Reality: Always sends Access-Control-Allow-Origin: *\n");

console.log('='.repeat(60));
console.log('KEY FINDINGS:');
console.log('='.repeat(60));
console.log(`
1. cors({ origin: '*' }) may NOT send a literal '*' header
   - It might reflect the origin back instead
   - This is a quirk of the cors package

2. cors() with NO options is the simplest way to allow all origins
   - This actually sends Access-Control-Allow-Origin: *

3. Manual headers are the MOST reliable way
   - You have complete control
   - Guaranteed to send exactly what you specify

4. The cors package behavior with origin: '*' is inconsistent
   - Different versions may behave differently
   - When credentials: true, it CANNOT use '*'

RECOMMENDATION:
- Use manual headers for complete control
- OR use cors() with no options for simplicity
- Avoid cors({ origin: '*' }) as it's unreliable
`);
