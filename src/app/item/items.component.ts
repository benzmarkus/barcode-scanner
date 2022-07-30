import {
  Component,
  ComponentFactoryResolver,
  NgZone,
  OnInit,
} from "@angular/core";
import { RouterExtensions } from "@nativescript/angular";
import { ItemEventData, Page } from "@nativescript/core";
import {
  clear,
  getString,
  setString,
} from "@nativescript/core/application-settings";
import { PlatformLocation } from "@angular/common";

@Component({
  selector: "ns-items",
  templateUrl: "./items.component.html",
})
export class ItemsComponent implements OnInit {
  barcodeList = [];
  showEditForm = false;
  activeBarcodeItem;
  constructor(
    private routerExtensions: RouterExtensions,
    private zone: NgZone,
    private location: PlatformLocation
  ) {}

  ngOnInit(): void {
    this.fetchList();
    this.location.onPopState(() => {
      this.fetchList();
    });
  }

  fetchList() {
    if (getString("barcodeList")) {
      this.barcodeList = JSON.parse(getString("barcodeList"));
    }
  }

  onItemTap(args: ItemEventData): void {
    console.log("Item with index: " + args.index + " tapped");
  }

  onScan() {
    this.zone.run(() => {
      this.routerExtensions.navigate(["scan"]);
    });
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

  onDelete(item) {
    const result = this.findBarcodeInListIndex(item.barcode);
    if (result !== -1) {
      this.barcodeList.splice(result, 1);
      setString("barcodeList", JSON.stringify(this.barcodeList));
      this.fetchList()
    }
  }

  onEdit(item) {
    this.activeBarcodeItem = item
    this.showEditForm = true
  }

  onCancelEdit() {
    this.showEditForm = false;
  }

  onSaveEdit() {
    this.showEditForm = false;
    const result = this.findBarcodeInListIndex(this.activeBarcodeItem.barcode);
    if ( result >= 0) {
      console.log("we found index" + result);
      this.barcodeList[result] = this.activeBarcodeItem;
      setString("barcodeList", JSON.stringify(this.barcodeList));
    }
  }
}
