import { Component, OnInit } from '@angular/core';
import { Application } from '@nativescript/core';
import { RadSideDrawer } from 'nativescript-ui-sidedrawer';

// registerElement("BarcodeScanner", () => require("nativescript-barcodescanner").BarcodeScannerView);
// <BarcodeScanner
// class="scanner-round"
// formats="QR_CODE, EAN_13"
// beepOnScan="true"
// reportDuplicates="true"
// preferFrontCamera="false">
// </BarcodeScanner>
@Component({
  selector: 'Home',
  templateUrl: './home.component.html',
})
export class HomeComponent implements OnInit {
  constructor() {
    // Use the component constructor to inject providers.
  }

  ngOnInit(): void {
    // Init your component properties here.
  }

  onDrawerButtonTap(): void {
    const sideDrawer = <RadSideDrawer>Application.getRootView()
    sideDrawer.showDrawer()
  }
}
