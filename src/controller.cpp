#include "controller.h"

#include "addressbook.h"
#include "settings.h"
#include "version.h"
#include "camount.h"
#include "websockets.h"

using json = nlohmann::json;

Controller::Controller(MainWindow* main) {
    auto cl = new ConnectionLoader(main, this);

    // Execute the load connection async, so we can set up the rest of RPC properly.
    QTimer::singleShot(1000, [=]() { cl->loadConnection(); });

    this->main = main;
    this->ui = main->ui;

    // Setup balances table model
    balancesTableModel = new BalancesTableModel(main->ui->balancesTable);
    main->ui->balancesTable->setModel(balancesTableModel);

    // Setup transactions table model
    transactionsTableModel = new TxTableModel(ui->transactionsTable);
    main->ui->transactionsTable->setModel(transactionsTableModel);

    // Set up timer to refresh Price
    priceTimer = new QTimer(main);
    QObject::connect(priceTimer, &QTimer::timeout, [=]() {
        if (Settings::getInstance()->getAllowFetchPrices())
            refreshZECPrice();
    });
    priceTimer->start(Settings::priceRefreshSpeed);  // Every hour

    // Set up a timer to refresh the UI every few seconds
    timer = new QTimer(main);
    QObject::connect(timer, &QTimer::timeout, [=]() {
        refresh(true);
        // Update the Send Tab
        main->updateFromCombo();
    });
    timer->start(Settings::updateSpeed);

    // Create the data model
    model = new DataModel();

    // Crate the ZcashdRPC
    zrpc = new LiteInterface();
}

Controller::~Controller() {
    delete timer;
    delete txTimer;

    delete transactionsTableModel;
    delete balancesTableModel;

    delete model;
    delete zrpc;
}


// Called when a connection to pirated is available.
void Controller::setConnection(Connection* c) {
    if (c == nullptr) return;

    this->zrpc->setConnection(c);

    ui->statusBar->showMessage("Ready!");

    // processInfo(c->getInfo());

    // If we're allowed to get the ARRR Price, get the prices
    if (Settings::getInstance()->getAllowFetchPrices())
        refreshZECPrice();

    // If we're allowed to check for updates, check for a new release
    if (Settings::getInstance()->getCheckForUpdates())
        checkForUpdate();


    isSyncing = new QAtomicInteger<bool>();
    isSyncing->storeRelaxed(true);

    syncingCounter = new QAtomicInteger<int>();
    syncingCounter->storeRelaxed(0);

    Settings::getInstance()->setSyncing(true);

    infoEndBlocks = new QAtomicInteger<int>();
    infoEndBlocks->storeRelaxed(0);

    infoSyncdBlocks = new QAtomicInteger<int>();
    infoSyncdBlocks->storeRelaxed(0);

    chainHeight = new QAtomicInteger<int>();
    chainHeight->storeRelaxed(0);

    walletHeight = new QAtomicInteger<int>();
    walletHeight->storeRelaxed(0);

    price = new QAtomicInteger<int>();
    price->storeRelaxed(0);

    QTimer::singleShot(1, [=]() {
        zrpc->syncWallet([=] (const json& reply) {

        }, [=](QString err) {

            QMessageBox::critical(main, QObject::tr("Connection Error"), QObject::tr("There was an error connecting to zcashd. The error was") + ": \n\n"
                + err, QMessageBox::StandardButton::Ok);

        });
    });

    synctimer = new QTimer(main);
    QObject::connect(synctimer, &QTimer::timeout, [=]() {

        zrpc->fetchInfo([=] (const json& reply) {
            // If success, set the connection
            c->setInfo(reply);

            if (reply.find("latest_block_height") != reply.end()) {
                if (reply["latest_block_height"].get<json::number_unsigned_t>() > 0)
                    chainHeight->storeRelaxed(reply["latest_block_height"].get<json::number_unsigned_t>());
            }

        }, [=](QString err) {
            QMessageBox::critical(main, QObject::tr("Connection Error"), QObject::tr("There was an error connecting to pirated. The error was") + ": \n\n"
                + err, QMessageBox::StandardButton::Ok);
        });

        zrpc->fetchLatestBlock([=] (const json& reply) {

            if (reply.find("height") != reply.end()) {
                if (reply["height"].get<json::number_unsigned_t>() > 0)
                    walletHeight->storeRelaxed(reply["height"].get<json::number_unsigned_t>());
            }
        }, [=](QString err) {
            QMessageBox::critical(main, QObject::tr("Connection Error"), QObject::tr("There was an error connecting to pirated. The error was") + ": \n\n"
                + err, QMessageBox::StandardButton::Ok);
        });


        zrpc->syncStatus([=] (const json& reply) {

            if (reply.find("end_block") != reply.end()) {
                syncingCounter->storeRelaxed(0);
                if (reply["end_block"].get<json::number_unsigned_t>() > 0)
                    infoEndBlocks->storeRelaxed(reply["end_block"].get<json::number_unsigned_t>());
            } else {
                int counter = syncingCounter->loadRelaxed();
                counter++;
                syncingCounter->storeRelaxed(counter);
            }

            if (Settings::getInstance()->isSyncing() && syncingCounter->loadRelaxed() > 30) {
                Settings::getInstance()->setSyncing(false);
            }

            if (reply.find("synced_blocks") != reply.end()) {
                if (reply["synced_blocks"].get<json::number_unsigned_t>() > 0)
                    infoSyncdBlocks->storeRelaxed(reply["synced_blocks"].get<json::number_unsigned_t>());
            }

        }, [=](QString err) {
            QMessageBox::critical(main, QObject::tr("Connection Error"), QObject::tr("There was an error connecting to pirated. The error was") + ": \n\n"
                + err, QMessageBox::StandardButton::Ok);
        });
    });



    QObject::connect(synctimer, &QTimer::timeout, [=]() {

        if (walletHeight->loadRelaxed() + 5 < chainHeight->loadRelaxed()) {
            isSyncing->storeRelaxed(true);
        } else {
            isSyncing->storeRelaxed(false);
        }

        if (isSyncing->loadRelaxed() && (infoEndBlocks->loadRelaxed() + infoSyncdBlocks->loadRelaxed() + 10 < chainHeight->loadRelaxed())) {
              main->statusLabel->setText(" Syncing: " + QString::number(infoEndBlocks->loadRelaxed() + infoSyncdBlocks->loadRelaxed()) + " / " + QString::number(chainHeight->loadRelaxed())  );
        } else {
              main->statusLabel->setText(" Current Block: " + QString::number(walletHeight->loadRelaxed()) + " |" + " ARRR/USD=$" + QString::number(   ((double)price->loadRelaxed())/1000      ) );
        }

        qApp->processEvents();
    });

    synctimer->setInterval(1 * 1000);
    synctimer->start();

    // Force update, because this might be coming from a settings update
    // where we need to immediately refresh
    refresh(true);
}

// Called during initial sync to allow interupt
void Controller::setLoadingConnection(Connection* c) {
    if (c == nullptr) return;

    this->zrpc->setLoadingConnection(c);
}


// Build the RPC JSON Parameters for this tx
void Controller::fillTxJsonParams(json& json_tx, Tx tx) {
    Q_ASSERT(json_tx.is_object());

    json_tx["input"]       = tx.fromAddr.toStdString();

    json allRecepients = json::array();
    // For each addr/amt/memo, construct the JSON and also build the confirm dialog box
    for (int i=0; i < tx.toAddrs.size(); i++) {
        auto toAddr = tx.toAddrs[i];

        // Construct the JSON params
        json rec = json::object();
        rec["address"]      = toAddr.addr.toStdString();
        rec["amount"]       = toAddr.amount.toqint64();
        if (Settings::isZAddress(toAddr.addr) && !toAddr.memo.trimmed().isEmpty())
            rec["memo"]     = toAddr.memo.toStdString();

        allRecepients.push_back(rec);
    }

    json_tx["output"]       = allRecepients;
    json_tx["fee"]          = tx.fee.toqint64();

}


void Controller::noConnection() {
    QIcon i = QApplication::style()->standardIcon(QStyle::SP_MessageBoxCritical);
    main->statusIcon->setPixmap(i.pixmap(16, 16));
    main->statusIcon->setToolTip("");
    // main->statusLabel->setText(QObject::tr("No Connection"));
    main->statusLabel->setToolTip("");
    // main->ui->statusBar->showMessage(QObject::tr("No Connection"), 1000);

    // Clear balances table.
    QMap<QString, CAmount> emptyBalances;
    QList<UnspentOutput>  emptyOutputs;
    QList<QString>        emptyAddresses;
    balancesTableModel->setNewData(emptyAddresses, emptyBalances, emptyOutputs);

    // Clear Transactions table.
    QList<TransactionItem> emptyTxs;
    transactionsTableModel->replaceData(emptyTxs);

    // Clear balances
    // ui->balSheilded->setText("");
    ui->balTotal->setText("");

    // ui->balSheilded->setToolTip("");
    ui->balTotal->setToolTip("");
}

/// This will refresh all the balance data from pirated
void Controller::refresh(bool force) {
    if (!zrpc->haveConnection())
        return noConnection();

    getInfoThenRefresh(force);
}

void Controller::processInfo(const json& info) {
    // Testnet?
    QString chainName;
    if (!info["chain_name"].is_null()) {
        chainName = QString::fromStdString(info["chain_name"].get<json::string_t>());
        Settings::getInstance()->setTestnet(chainName == "test");
    };


    QString version = QString::fromStdString(info["version"].get<json::string_t>());
    Settings::getInstance()->setZcashdVersion(version);

    QString vversion = QString(APP_VERSION) % " (" % QString(__DATE__) % ")";
    ui->version->setText(version);
    ui->vendor->setText(vversion);

    // Recurring payments are testnet only
    if (!Settings::getInstance()->isTestnet())
        main->disableRecurring();
}

void Controller::getInfoThenRefresh(bool force) {
    if (!zrpc->haveConnection())
        return noConnection();

    static bool prevCallSucceeded = false;

    if (!isSyncing->loadRelaxed()) {
        Settings::getInstance()->setSyncing(false);
    } else {
        Settings::getInstance()->setSyncing(true);
    }

    if (!Settings::getInstance()->isSyncing()) {
        main->logger->write(QString("Run Sync Wallet "));
        zrpc->syncWallet([=] (const json& reply) {
          QString syncStatus  = QString::fromStdString(reply["result"].get<json::string_t>());

          main->logger->write(QString("Sync Wallet ") % syncStatus);

        }, [=](QString err) {
            // zcashd has probably disappeared.
            this->noConnection();

            // Prevent multiple dialog boxes, because these are called async
            static bool shown = false;
            if (!shown && prevCallSucceeded) { // show error only first time
                shown = true;
                QMessageBox::critical(main, QObject::tr("Connection Error"), QObject::tr("There was an error connecting to zcashd. The error was") + ": \n\n"
                    + err, QMessageBox::StandardButton::Ok);
                shown = false;
            }

            prevCallSucceeded = false;
        });
    }


    zrpc->fetchLatestBlock([=] (const json& reply) {
        prevCallSucceeded = true;

        int curBlock = reply["height"].get<json::number_integer_t>();
        bool doUpdate = force || (model->getLatestBlock() != curBlock);

        price->storeRelaxed((int) Settings::getInstance()->getZECPrice()*1000);

        model->setLatestBlock(curBlock);
        ui->blockheight->setText(QString::number(curBlock));

        main->logger->write(QString("Refresh. curblock ") % QString::number(curBlock) % ", update=" % (doUpdate ? "true" : "false") );

        // Connected, so display checkmark.
        auto tooltip = Settings::getInstance()->getSettings().server + "\n" +
                            QString::fromStdString(zrpc->getConnection()->getInfo().dump());
        QIcon i(":/icons/res/connected.gif");
        QString chainName = Settings::getInstance()->isTestnet() ? "test" : "main";
        main->statusLabel->setVisible(true);
        main->statusLabel->setToolTip(tooltip);
        main->statusIcon->setPixmap(i.pixmap(16, 16));
        main->statusIcon->setToolTip(tooltip);

        // See if recurring payments needs anything
        Recurring::getInstance()->processPending(main);

        // Check if the wallet is locked/encrypted
        zrpc->fetchWalletEncryptionStatus([=] (const json& reply) {
            bool isEncrypted = reply["encrypted"].get<json::boolean_t>();
            bool isLocked = reply["locked"].get<json::boolean_t>();

            model->setEncryptionStatus(isEncrypted, isLocked);
        });

        if ( doUpdate ) {
            // Something changed, so refresh everything.
            refreshBalances();
            refreshAddresses();     // This calls refreshZSentTransactions() and refreshReceivedZTrans()
            refreshTransactions();
        }
    }, [=](QString err) {
        // pirated has probably disappeared.
        this->noConnection();

        // Prevent multiple dialog boxes, because these are called async
        static bool shown = false;
        if (!shown && prevCallSucceeded) { // show error only first time
            shown = true;
            QMessageBox::critical(main, QObject::tr("Connection Error"), QObject::tr("There was an error connecting to pirated. The error was") + ": \n\n"
                + err, QMessageBox::StandardButton::Ok);
            shown = false;
        }

        prevCallSucceeded = false;
    });
}

void Controller::refreshAddresses() {
    if (!zrpc->haveConnection())
        return noConnection();

    auto newzaddresses = new QList<QString>();

    zrpc->fetchAddresses([=] (json reply) {
        auto zaddrs = reply["z_addresses"].get<json::array_t>();
        for (auto& it : zaddrs) {
            auto addr = QString::fromStdString(it.get<json::string_t>());
            newzaddresses->push_back(addr);
        }

        model->replaceZaddresses(newzaddresses);
    });

}

// Function to create the data model and update the views, used below.
void Controller::updateUI(bool anyUnconfirmed) {
    ui->unconfirmedWarning->setVisible(anyUnconfirmed);

    // Update balances model data, which will update the table too
    balancesTableModel->setNewData(model->getAllZAddresses(), model->getAllBalances(), model->getUTXOs());

    // Update from address
    main->updateFromCombo();
};

// Function to process reply of the listunspent and z_listunspent API calls, used below.
void Controller::processUnspent(const json& reply, QMap<QString, CAmount>* balancesMap, QList<UnspentOutput>* unspentOutputs) {
    auto processFn = [=](const json& array) {
        for (auto& it : array) {
            QString qsAddr  = QString::fromStdString(it["address"]);
            int block       = it["created_in_block"].get<json::number_unsigned_t>();
            QString txid    = QString::fromStdString(it["created_in_txid"]);
            CAmount amount  = CAmount::fromqint64(it["value"].get<json::number_unsigned_t>());

            bool spendable = it["unconfirmed_spent"].is_null() && it["spent"].is_null();    // TODO: Wait for 4 confirmations
            bool pending   = !it["unconfirmed_spent"].is_null();

            unspentOutputs->push_back(UnspentOutput{ qsAddr, txid, amount, block, spendable, pending });
            if (spendable) {
                (*balancesMap)[qsAddr] = (*balancesMap)[qsAddr] +
                                         CAmount::fromqint64(it["value"].get<json::number_unsigned_t>());
            }
        }
    };

    processFn(reply["unspent_notes"].get<json::array_t>());
    processFn(reply["utxos"].get<json::array_t>());
    processFn(reply["pending_notes"].get<json::array_t>());
    processFn(reply["pending_utxos"].get<json::array_t>());
};

void Controller::updateUIBalances() {
    CAmount balZ = getModel()->getBalZ();
    // CAmount balVerified = getModel()->getBalVerified();

    // Reduce the BalanceZ by the pending outgoing amount. We're adding
    // here because totalPending is already negative for outgoing txns.
    balZ = balZ + getModel()->getTotalPending();
    if (balZ < 0) {
        balZ = CAmount::fromqint64(0);
    }

    // CAmount balUnconfirmed     = balVerified - balZ;
    // CAmount balConfirmed       = balVerified;

    // Balances table
    // ui->balUnconfirmed  ->setText(balUnconfirmed.toDecimalZECString());
    // ui->balConfirmed    ->setText(balConfirmed.toDecimalZECString());
    ui->balTotal        ->setText(balZ.toDecimalZECString());

    // ui->balUnconfirmed  ->setToolTip(balUnconfirmed.toDecimalUSDString());
    // ui->balConfirmed    ->setToolTip(balConfirmed.toDecimalUSDString());
    ui->balTotal        ->setToolTip(balZ.toDecimalUSDString());

    // Send tab
    // ui->txtAvailableZEC->setText(balAvailable.toDecimalZECString());
     ui->balUSDTotal->setText(balZ.toDecimalUSDString());
}

void Controller::refreshBalances() {
    if (!zrpc->haveConnection())
        return noConnection();

    // 1. Get the Balances
    zrpc->fetchBalance([=] (json reply) {
        CAmount balZ        = CAmount::fromqint64(reply["zbalance"].get<json::number_unsigned_t>());
        CAmount balVerified = CAmount::fromqint64(reply["verified_zbalance"].get<json::number_unsigned_t>());

        model->setBalZ(balZ);
        // model->setBalVerified(balVerified);

        // This is for the websockets
        AppDataModel::getInstance()->setBalances(balZ);

        // This is for the datamodel
        CAmount balAvailable = balVerified;
        model->setAvailableBalance(balAvailable);

        updateUIBalances();
    });

    // 2. Get the UTXOs
    // First, create a new UTXO list. It will be replacing the existing list when everything is processed.
    auto newUnspentOutputs = new QList<UnspentOutput>();
    auto newBalances = new QMap<QString, CAmount>();

    // Call the Transparent and Z unspent APIs serially and then, once they're done, update the UI
    zrpc->fetchUnspent([=] (json reply) {
        processUnspent(reply, newBalances, newUnspentOutputs);

        // Swap out the balances and UTXOs
        model->replaceBalances(newBalances);
        model->replaceUTXOs(newUnspentOutputs);

        // Find if any output is not spendable or is pending
        bool anyUnconfirmed = std::find_if(newUnspentOutputs->constBegin(), newUnspentOutputs->constEnd(),
                                    [=](const UnspentOutput& u) -> bool {
                                        return !u.spendable ||  u.pending;
                              }) != newUnspentOutputs->constEnd();

        updateUI(anyUnconfirmed);

        main->balancesReady();
    });
}

void Controller::refreshTransactions() {
    if (!zrpc->haveConnection())
        return noConnection();

    zrpc->fetchTransactions([=] (json reply) {
        QList<TransactionItem> txdata;

        for (auto& it : reply.get<json::array_t>()) {
            QString address;
            CAmount total_amount;
            QList<TransactionItemDetail> items;

            long confirmations;
            if (it.find("unconfirmed") != it.end() && it["unconfirmed"].get<json::boolean_t>()) {
                confirmations = 0;
            } else {
                confirmations = model->getLatestBlock() - it["block_height"].get<json::number_integer_t>() + 1;
            }

            auto txid = QString::fromStdString(it["txid"]);
            auto datetime = it["datetime"].get<json::number_integer_t>();

            if (!it["incoming_metadata"].is_null()) {

                for (auto o: it["incoming_metadata"].get<json::array_t>()) {
                    QList<TransactionItemDetail> items;
                    QString address = QString::fromStdString(o["address"]);
                    CAmount amount = CAmount::fromqint64(1 * o["value"].get<json::number_unsigned_t>());
                    QString memo;
                    if (!o["memo"].is_null()) {
                        memo = QString::fromStdString(o["memo"]);
                    }

                    items.push_back(TransactionItemDetail{address, amount, memo});
                    txdata.push_back(TransactionItem{
                       "Receive", datetime, address, txid, confirmations, items
                    });
                }
            }

            if (Settings::getInstance()->getShowTxFee()) {
              QList<TransactionItemDetail> items;
              QString address = QString::fromStdString("Tx Fee");
              CAmount amount = CAmount::fromqint64(-1 * it["fee"].get<json::number_unsigned_t>());
              QString memo;

              items.push_back(TransactionItemDetail{address, amount, memo});

              if (it["fee"].get<json::number_unsigned_t>() > 0) {
                txdata.push_back(TransactionItem{
                   "Fee", datetime, address, txid, confirmations, items
                });
              }
            }

            if (!it["outgoing_metadata"].is_null()) {

                for (auto o: it["outgoing_metadata"].get<json::array_t>()) {
                    QList<TransactionItemDetail> items;
                    QString address = QString::fromStdString(o["address"]);
                    CAmount amount = CAmount::fromqint64(-1 * o["value"].get<json::number_unsigned_t>());
                    QString memo;
                    if (!o["memo"].is_null()) {
                        memo = QString::fromStdString(o["memo"]);
                    }

                    items.push_back(TransactionItemDetail{address, amount, memo});
                    txdata.push_back(TransactionItem{
                       "Sent", datetime, address, txid, confirmations, items
                    });
                }
            }


            if ((it["outgoing_metadata"].is_null() && it["incoming_metadata"].is_null()) || Settings::getInstance()->getShowChangeTxns()) {
                if (!it["incoming_metadata_change"].is_null()) {
                    for (auto o: it["incoming_metadata_change"].get<json::array_t>()) {
                        QList<TransactionItemDetail> items;
                        QString address = QString::fromStdString(o["address"]);
                        CAmount amount = CAmount::fromqint64(-1 * o["value"].get<json::number_unsigned_t>());
                        QString memo;
                        if (!o["memo"].is_null()) {
                            memo = QString::fromStdString(o["memo"]);
                        }

                        items.push_back(TransactionItemDetail{address, amount, memo});
                        txdata.push_back(TransactionItem{
                           "Change Received", datetime, address, txid, confirmations, items
                        });
                    }
                }
                if (!it["outgoing_metadata_change"].is_null()) {
                    for (auto o: it["outgoing_metadata_change"].get<json::array_t>()) {
                        QList<TransactionItemDetail> items;
                        QString address = QString::fromStdString(o["address"]);
                        CAmount amount = CAmount::fromqint64(-1 * o["value"].get<json::number_unsigned_t>());
                        QString memo;
                        if (!o["memo"].is_null()) {
                            memo = QString::fromStdString(o["memo"]);
                        }

                        items.push_back(TransactionItemDetail{address, amount, memo});
                        txdata.push_back(TransactionItem{
                           "Change Sent", datetime, address, txid, confirmations, items
                        });
                    }
                }
            }



        }

        // Calculate the total unspent amount that's pending. This will need to be
        // shown in the UI so the user can keep track of pending funds
        CAmount totalPending;
        for (auto txitem : txdata) {
            if (txitem.confirmations == 0) {
                for (auto item: txitem.items) {
                    totalPending = totalPending + item.amount;
                }
            }
        }
        getModel()->setTotalPending(totalPending);

        // Update UI Balance
        updateUIBalances();

        // Update model data, which updates the table view
        transactionsTableModel->replaceData(txdata);
    });
}

// If the wallet is encrpyted and locked, we need to unlock it
void Controller::unlockIfEncrypted(std::function<void(void)> cb, std::function<void(void)> error) {
    auto encStatus = getModel()->getEncryptionStatus();
    if (encStatus.first && encStatus.second) {
        // Wallet is encrypted and locked. Ask for the password and unlock.
        QString password = QInputDialog::getText(main, main->tr("Wallet Password"),
                            main->tr("Your wallet is encrypted.\nPlease enter your wallet password"), QLineEdit::Password);

        if (password.isEmpty()) {
            QMessageBox::critical(main, main->tr("Wallet Decryption Failed"),
                main->tr("Please enter a valid password"),
                QMessageBox::Ok
            );
            error();
            return;
        }

        zrpc->unlockWallet(password, [=](json reply) {
            if (isJsonResultSuccess(reply)) {
                cb();

                // Refresh the wallet so the encryption status is now in sync.
                refresh(true);
            } else {
                QMessageBox::critical(main, main->tr("Wallet Decryption Failed"),
                    QString::fromStdString(reply["error"].get<json::string_t>()),
                    QMessageBox::Ok
                );
                error();
            }
        });
    } else {
        // Not locked, so just call the function
        cb();
    }
}

/**
 * Execute a transaction with the standard UI. i.e., standard status bar message and standard error
 * handling
 */
void Controller::executeStandardUITransaction(Tx tx) {
    executeTransaction(tx,
        [=] (QString txid) {
            ui->statusBar->showMessage(Settings::txidStatusMessage + " " + txid);
        },
        [=] (QString opid, QString errStr) {
            ui->statusBar->showMessage(QObject::tr(" Tx ") % opid % QObject::tr(" failed"), 15 * 1000);

            if (!opid.isEmpty())
                errStr = QObject::tr("The transaction with id ") % opid % QObject::tr(" failed. The error was") + ":\n\n" + errStr;

            QMessageBox::critical(main, QObject::tr("Transaction Error"), errStr, QMessageBox::Ok);
        }
    );
}


// Execute a transaction!
void Controller::executeTransaction(Tx tx,
        const std::function<void(QString txid)> submitted,
        const std::function<void(QString txid, QString errStr)> error) {
    unlockIfEncrypted([=] () {
        // First, create the json params
        json params = json::object();
        //json params = json::array();
        fillTxJsonParams(params, tx);
        std::cout << std::setw(2) << params << std::endl;

        zrpc->sendTransaction(QString::fromStdString(params.dump()), [=](const json& reply) {
            if (reply.find("txid") == reply.end()) {
                error("", "Couldn't understand Response: " + QString::fromStdString(reply.dump()));
            } else {
                QString txid = QString::fromStdString(reply["txid"].get<json::string_t>());
                submitted(txid);
            }
        },
        [=](QString errStr) {
            error("", errStr);
        });
    }, [=]() {
        error("", main->tr("Failed to unlock wallet"));
    });
}


void Controller::checkForUpdate(bool silent) {
    if (!zrpc->haveConnection())
        return noConnection();

    QUrl cmcURL("https://api.github.com/repos/PirateNetwork/PirateWallet-Lite/releases");

    QNetworkRequest req;
    req.setUrl(cmcURL);

    QNetworkAccessManager *manager = new QNetworkAccessManager(this->main);
    QNetworkReply *reply = manager->get(req);

    QObject::connect(reply, &QNetworkReply::finished, [=] {
        reply->deleteLater();
        manager->deleteLater();

        try {
            if (reply->error() == QNetworkReply::NoError) {

                auto releases = QJsonDocument::fromJson(reply->readAll()).array();
                QVersionNumber maxVersion(0, 0, 0);

                for (QJsonValue rel : releases) {
                    if (!rel.toObject().contains("tag_name"))
                        continue;

                    QString tag = rel.toObject()["tag_name"].toString();
                    if (tag.startsWith("v"))
                        tag = tag.right(tag.length() - 1);

                    if (!tag.isEmpty()) {
                        auto v = QVersionNumber::fromString(tag);
                        if (v > maxVersion)
                            maxVersion = v;
                    }
                }

                auto currentVersion = QVersionNumber::fromString(APP_VERSION);

                // Get the max version that the user has hidden updates for
                QSettings s;
                auto maxHiddenVersion = QVersionNumber::fromString(s.value("update/lastversion", "0.0.0").toString());

                qDebug() << "Version check: Current " << currentVersion << ", Available " << maxVersion;

                if (maxVersion > currentVersion && (!silent || maxVersion > maxHiddenVersion)) {
                    auto ans = QMessageBox::information(main, QObject::tr("Update Available"),
                        QObject::tr("A new release v%1 is available! You have v%2.\n\nWould you like to visit the releases page?")
                            .arg(maxVersion.toString())
                            .arg(currentVersion.toString()),
                        QMessageBox::Yes, QMessageBox::Cancel);
                    if (ans == QMessageBox::Yes) {
                        QDesktopServices::openUrl(QUrl("https://github.com/Piratenetwork/PirateWallet-Lite/releases"));
                    } else {
                        // If the user selects cancel, don't bother them again for this version
                        s.setValue("update/lastversion", maxVersion.toString());
                    }
                } else {
                    if (!silent) {
                        QMessageBox::information(main, QObject::tr("No updates available"),
                            QObject::tr("You already have the latest release v%1")
                                .arg(currentVersion.toString()));
                    }
                }
            }
        }
        catch (...) {
            // If anything at all goes wrong, just set the price to 0 and move on.
            qDebug() << QString("Caught something nasty - check for update");
        }
    });
}

// Get the ARRR->USD price from coinmarketcap using their API
void Controller::refreshZECPrice() {
    if (!zrpc->haveConnection())
        return noConnection();

    QUrl cmcURL("https://api.coingecko.com/api/v3/simple/price?ids=pirate-chain&vs_currencies=btc%2Cusd%2Ceur&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true");

    QNetworkRequest req;
    req.setUrl(cmcURL);

    QNetworkAccessManager *manager = new QNetworkAccessManager(this->main);
    QNetworkReply *reply = manager->get(req);

    QObject::connect(reply, &QNetworkReply::finished, [=] {
        reply->deleteLater();
        manager->deleteLater();

        try {
            if (reply->error() != QNetworkReply::NoError) {
                auto parsed = json::parse(reply->readAll(), nullptr, false);
                if (!parsed.is_discarded() && !parsed["error"]["message"].is_null()) {
                    qDebug() << QString::fromStdString(parsed["error"]["message"]);
                } else {
                    qDebug() << reply->errorString();
                }
                Settings::getInstance()->setZECPrice(0);
                return;
            }

            auto all = reply->readAll();

            auto parsed = json::parse(all, nullptr, false);
            if (parsed.is_discarded()) {
                Settings::getInstance()->setZECPrice(0);
                return;
            }

            // Grab prices from CMC
            //for (const json& item : parsed.get<json::array_t>()) {
            //    if (item["symbol"].get<json::string_t>() == Settings::getTokenName().toStdString()) {
            //        QString price = QString::fromStdString(item["price_usd"].get<json::string_t>());
            //        qDebug() << Settings::getTokenName() << " Price=" << price;
            //        Settings::getInstance()->setZECPrice(price.toDouble());

            //        return;
            //    }
            //}

            // Grab prices from CoinGecko
            const json& item  = parsed.get<json::object_t>();
            const json& arrr  = item["pirate-chain"].get<json::object_t>();

            if (arrr["usd"] >= 0) {
                qDebug() << "Found pirate-chain key in price json";
                // TODO: support BTC/EUR prices as well
                //QString price = QString::fromStdString(arrr["usd"].get<json::string_t>());
                qDebug() << "ARRR = $" << QString::number((double)arrr["usd"]);
                Settings::getInstance()->setZECPrice( arrr["usd"] );

                return;
            }
        } catch (...) {
            // If anything at all goes wrong, just set the price to 0 and move on.
            qDebug() << QString("Caught something nasty - refresh Arrr Price");
        }

        // If nothing, then set the price to 0;
        Settings::getInstance()->setZECPrice(0);
    });
}

void Controller::shutdownZcashd() {
    // Save the wallet and exit the lightclient library cleanly.
    if (zrpc->haveConnection()) {
        QDialog d(main);
        Ui_ConnectionDialog connD;
        connD.setupUi(&d);
        connD.topIcon->setPixmap(QIcon(":/icons/res/logo.ico").pixmap(256, 256));
        connD.status->setText(QObject::tr("Please wait for PirateWallet to exit"));
        connD.statusDetail->setText(QObject::tr("Waiting for pirated to exit"));

        bool finished = false;

        zrpc->stopWallet([&] (json) {
            if (!finished)
                d.accept();
            finished = true;
        });

        if (!finished)
            d.exec();
    }
}

/**
 * Get a Sapling address from the user's wallet
 */
QString Controller::getDefaultSaplingAddress() {
    for (QString addr: model->getAllZAddresses()) {
        if (Settings::getInstance()->isSaplingAddress(addr))
            return addr;
    }

    return QString();
}

// QString Controller::getDefaultTAddress() {
//     if (model->getAllTAddresses().length() > 0)
//         return model->getAllTAddresses().at(0);
//     else
//         return QString();
// }
