import { NgModule } from '@angular/core'
import { Routes } from '@angular/router'
import { NativeScriptRouterModule } from '@nativescript/angular'

import { ItemsComponent } from './item/items.component'
import { ScanbarcodeComponent } from './scanBarcode/scanBarcode.component'

const routes: Routes = [
  { path: "home", component: ItemsComponent, },
  { path: "scan", component: ScanbarcodeComponent },
  { path: "", redirectTo: "/home", pathMatch: "full" },
]

@NgModule({
  imports: [NativeScriptRouterModule.forRoot(routes)],
  exports: [NativeScriptRouterModule],
})
export class AppRoutingModule {}
