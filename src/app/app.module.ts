import { NgModule, NO_ERRORS_SCHEMA } from '@angular/core'
import { NativeScriptFormsModule, NativeScriptModule, registerElement } from '@nativescript/angular'
import { AppRoutingModule } from './app-routing.module'
import { AppComponent } from './app.component'
import { ItemsComponent } from './item/items.component'
import {ScanbarcodeComponent} from './scanBarcode/scanBarcode.component'
registerElement("BarcodeScanner", () => require("nativescript-barcodescanner").BarcodeScannerView);
@NgModule({
  bootstrap: [AppComponent],
  imports: [NativeScriptModule, AppRoutingModule,
    NativeScriptFormsModule
  ],
  declarations: [AppComponent, ItemsComponent, ScanbarcodeComponent],
  providers: [],
  schemas: [NO_ERRORS_SCHEMA],
})
export class AppModule {}
