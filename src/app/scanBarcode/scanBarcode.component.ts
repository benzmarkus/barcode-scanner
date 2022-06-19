import { Component, NgZone, OnInit } from "@angular/core";
import { RouterExtensions } from "@nativescript/angular";
import {
  clear,
  getString,
  setString,
} from "@nativescript/core/application-settings";

import { BarcodeScanner } from "nativescript-barcodescanner";
@Component({
  selector: "Scanbarcode",
  moduleId: module.id,
  templateUrl: "./scanBarcode.component.html",
  styleUrls: ["./scanBarcode.component.css"],
})
export class ScanbarcodeComponent implements OnInit {
  textFieldValue: string = "";

  isNewBarcode = false;
  isBarcodeScanned = false;
  barcodeList = [];
  activeBarcodeItem: any;
  scannedBarcodeItem = {
    title: "",
    price: "",
    barcodeType: "",
    barcode: "",
  };
  showEditForm = false;
  barcodescanner;

  constructor(
    private routerExtensions: RouterExtensions,
    private zone: NgZone
  ) {
    this.barcodescanner = new BarcodeScanner();
  }

  ngOnInit(): void {
    this.startScanBarcode();
    if (getString("barcodeList")) {
      this.barcodeList = JSON.parse(getString("barcodeList"));
    }
    console.log("working" + new Date());
  }

  startScanBarcode() {
    this.barcodescanner.scan({}).then((res) => {
      console.log(res);
      this.isBarcodeScanned = true;
      if (JSON.parse(res.text)) {
        this.scannedBarcodeItem = JSON.parse(res.text);
        this.onScan(this.scannedBarcodeItem);
      }
    });
  }

  findBarcodeInList(newBarcode) {
    let isExistItem = {};
    this.barcodeList &&
      this.barcodeList.length >= 1 &&
      this.barcodeList.forEach((item) => {
        if (item.barcode == newBarcode) {
          isExistItem = item;
        }
      });
    return isExistItem;
  }

  findBarcodeInListIndex(newBarcode) {
    let isExistItemIndex = -1;
    this.barcodeList &&
      this.barcodeList.length >= 1 &&
      this.barcodeList.forEach((item, index) => {
        if (item.barcode == newBarcode) {
          isExistItemIndex = index;
        }
      });
    return isExistItemIndex;
  }

  onScan(scannedBarcodeItem): void {
    this.activeBarcodeItem = this.findBarcodeInList(scannedBarcodeItem.barcode);
    if (this.activeBarcodeItem && this.activeBarcodeItem.barcode) {
      this.isNewBarcode = false;
    } else {
      this.isNewBarcode = true;
    }
  }

  onRegisterNewBarcode() {
    const isBarcodeItem: any = this.findBarcodeInList(
      this.scannedBarcodeItem.barcode
    );
    if (isBarcodeItem && !isBarcodeItem.barcode) {
      this.barcodeList.push(this.scannedBarcodeItem);
      console.log(this.barcodeList);
      setTimeout(() => {
        setString("barcodeList", JSON.stringify(this.barcodeList));
        alert("New Barocde Added");
        this.routerExtensions.back();
      }, 1000);
    }
  }

  onEdit(): void {
    this.showEditForm = true;
  }

  onCancelEdit() {
    this.showEditForm = false;
  }

  onSaveEdit() {
    this.showEditForm = false;
    const result = this.findBarcodeInListIndex(this.activeBarcodeItem.barcode);
    if (result && result > 0) {
      this.isNewBarcode = false;
      console.log("we found index" + result);
      this.barcodeList[result] = this.activeBarcodeItem;
      setString("barcodeList", JSON.stringify(this.barcodeList));
    }
  }

  goBack() {
    this.zone.run(() => {
      this.routerExtensions.back();
    });
  }
}
