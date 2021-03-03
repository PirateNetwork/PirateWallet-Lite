## ZerWallet Lite
Zerwallet-Lite is z-Addr first, Sapling compatible lightwallet client for Zero. It has full support for all Zero features:
- Send + Receive fully shielded transactions
- Supports transparent addresses and transactions
- Full support for incoming and outgoing memos
- Fully encrypt your private keys, using viewkeys to sync the blockchain

## Download
Download compiled binaries from our [release page](https://github.com/zerocurrencycoin/zerwallet-lite/releases)

## Privacy
* While all the keys and transaction detection happens on the client, the server can learn what blocks contain your shielded transactions.
* The server also learns other metadata about you like your ip address etc...
* Also remember that t-addresses don't provide any privacy protection.

## Compiling from source
* ZerWallet is written in C++ 14, and can be compiled with g++/clang++/visual c++.
* It also depends on Qt5, which you can get from [here](https://www.qt.io/download).
* You'll need Rust v1.37 +

### Building on Linux

```
git clone https://github.com/zerocurrencycoin/zerwallet-lite.git
cd zerwallet-lite
/path/to/qt5/bin/qmake zerwallet-lite.pro CONFIG+=debug
make -j$(nproc)

./zerwallet-lite
```
