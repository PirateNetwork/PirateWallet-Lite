PirateWallet-Lite is z-Addr first, Sapling compatible wallet lightwallet for Pirate. It has full support for all Pirate features:
- Send + Receive fully shielded transactions
- Full support for incoming and outgoing memos
- Fully encrypt your private keys, using viewkeys to sync the blockchain

## Download
Download compiled binaries from our [release page](https://github.com/MrMLynch/piratewallet-lite/releases)

## Privacy
* While all the keys and transaction detection happens on the client, the server can learn what blocks contain your shielded transactions.
* The server also learns other metadata about you like your ip address etc - this can be mitigated by running your lightd server (HOW-TO will be posted shortly)


### Note Management
PirateWallet-Lite does automatic note and utxo management, which means it doesn't allow you to manually select which address to send outgoing transactions from. It follows these principles:
* Defaults to sending shielded transactions.
* Sapling funds need at least 5 confirmations before they can be spent
* Can select funds from multiple shielded addresses in the same transaction

## Compiling from source
* PirateWallet-Lite is written in C++ 14, and can be compiled with g++/clang++/visual c++.
* It also depends on Qt5, which you can get from [here](https://www.qt.io/download).
* You'll need Rust v1.37 +

### Building on Linux

```
git clone https://github.com/MrMLynch/piratewallet-lite.git
cd piratewallet-lite
/path/to/qt5/bin/qmake piratewallet-lite.pro CONFIG+=debug
make -j$(nproc)

./piratewallet-lite
```
