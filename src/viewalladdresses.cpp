#include "viewalladdresses.h"
#include "camount.h"
#include "settings.h"

ViewAllAddressesModel::ViewAllAddressesModel(QTableView *parent, Controller* rpc)
     : QAbstractTableModel(parent) {
    headers << tr("Address") << tr("Balance (%1)").arg(Settings::getTokenName());
    this->rpc = rpc;

    //Set Addresses
    auto addrs = this->rpc->getModel()->getAllZAddresses();
    replaceData(addrs);
}

void ViewAllAddressesModel::replaceData(QList<QString>& data) {
    addresses.clear();

    // Copy over the data and sort it
    for(QList<QString>::iterator it = data.begin(); it != data.end(); it++) {
        addresses.append(*it);
    }

    dataChanged(index(0, 0), index(addresses.size()-1, columnCount(index(0,0))-1));
    layoutChanged();
}

int ViewAllAddressesModel::rowCount(const QModelIndex&) const {
    return addresses.size();
}

int ViewAllAddressesModel::columnCount(const QModelIndex&) const {
    return headers.size();
}

QVariant ViewAllAddressesModel::data(const QModelIndex &index, int role) const {
    QString address = addresses.at(index.row());
    if (role == Qt::DisplayRole) {
        switch(index.column()) {
            case 0: return address;
            case 1: return rpc->getModel()->getAllBalances().value(address, CAmount::fromqint64(0)).toDecimalString();
        }
    }
    return QVariant();
}  


QVariant ViewAllAddressesModel::headerData(int section, Qt::Orientation orientation, int role) const {
    if (role == Qt::DisplayRole && orientation == Qt::Horizontal) {
        return headers.at(section);
    }

    return QVariant();
}
