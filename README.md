## Safe{Guard}

A standard Safe Smart Account guard that prevents common footguns:
- `DELEGATECALL` transactions, which are _mostly_ evil
- Unauthorized module access, making it harder to sneakily enable modules
