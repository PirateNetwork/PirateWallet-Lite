#include "liteinterface.h"

LiteInterface::LiteInterface() {

}

LiteInterface::~LiteInterface() {
    delete conn;
}

void LiteInterface::setConnection(Connection* c) {
    if (conn) {
        delete conn;
    }

    conn = c;
}

void LiteInterface::setLoadingConnection(Connection* c) {
    if (loadingConn) {
        delete loadingConn;
    }

    loadingConn = c;
}

bool LiteInterface::haveConnection() {
    return conn != nullptr;
}

bool LiteInterface::haveLoadingConnection() {
    return loadingConn != nullptr;
}

void LiteInterface::fetchAddresses(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("addresses", "", cb);
}


void LiteInterface::fetchUnspent(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("notes", "", cb);
}

void LiteInterface::createNewZaddr(bool, const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("new", "z", cb);
}

// void LiteInterface::createNewTaddr(const std::function<void(json)>& cb) {
//    if (conn == nullptr)
//        return;

//    conn->doRPCWithDefaultErrorHandling("new", "R", cb);
// }

void LiteInterface::fetchPrivKey(QString addr, const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("export", addr, cb);
}

void LiteInterface::fetchSeed(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("seed", "", cb);
}

void LiteInterface::fetchBalance(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("balance", "", cb);
}

void LiteInterface::fetchTransactions(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("list", "", cb);
}

void LiteInterface::saveWallet(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("save", "", cb);
}

void LiteInterface::clearWallet(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("clear", "", cb);
}

void LiteInterface::stopWallet(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("stop", "", cb);
}

void LiteInterface::rescanWallet(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("rescan", "", cb);
}

void LiteInterface::unlockWallet(QString password, const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("unlock", password, cb);
}

void LiteInterface::fetchWalletEncryptionStatus(const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("encryptionstatus", "", cb);
}

void LiteInterface::encryptWallet(QString password, const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("encrypt", password, cb);
}


void LiteInterface::removeWalletEncryption(QString password, const std::function<void(json)>& cb) {
    if (conn == nullptr)
        return;

    conn->doRPCWithDefaultErrorHandling("decrypt", password, cb);
}


void LiteInterface::sendTransaction(QString params, const std::function<void(json)>& cb,
    const std::function<void(QString)>& err) {
    if (conn == nullptr)
        return;

    conn->doRPC("send", params, cb, err);
}

void LiteInterface::fetchInfo(const std::function<void(json)>& cb,
    const std::function<void(QString)>&  err) {
    if (conn == nullptr)
        return;

    conn->doRPC("info", "", cb, err);
}


void LiteInterface::fetchLatestBlock(const std::function<void(json)>& cb,
                        const std::function<void(QString)>& err) {
    if (conn == nullptr)
        return;

    conn->doRPC("height", "", cb, err);
}

void LiteInterface::syncWallet(const std::function<void(json)>& cb,
                        const std::function<void(QString)>& err) {
    if (conn == nullptr)
        return;

    conn->doRPC("sync", "", cb, err);
}

void LiteInterface::syncStatus(const std::function<void(json)>& cb,
                        const std::function<void(QString)>& err) {
    if (conn == nullptr)
        return;

    conn->doRPC("syncstatus", "", cb, err);
}


/**
 * Method to get all the private keys for both z and R addresses. It will make 2 batch calls,
 * combine the result, and call the callback with a single list containing both the t-addr and z-addr
 * private keys
 */
void LiteInterface::fetchAllPrivKeys(const std::function<void(json)> cb) {
    if (conn == nullptr) {
        // No connection, just return
        return;
    }

    conn->doRPCWithDefaultErrorHandling("export", "", cb);
}
