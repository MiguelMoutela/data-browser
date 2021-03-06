import {ErrorHandler, NgModule} from '@angular/core';
import {FormsModule, ReactiveFormsModule} from '@angular/forms';
import {Http, HttpModule, RequestOptions, XHRBackend} from '@angular/http';
import {BrowserModule} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {ClarityModule} from '@clr/angular';
import {environment} from 'environments/environment';
import { ResponsiveModule } from 'ngx-responsive';
import * as StackTrace from 'stacktrace-js';
import {ErrorReporterService} from './services/error-reporter.service';

import {AppComponent, overriddenUrlKey} from './views/app/app.component';

/* Our Modules */
import {
  ApiModule,
  Configuration
} from 'publicGenerated';


import { AppRoutingModule } from './app-routing.module';
import { DataBrowserModule } from './data-browser/data-browser.module';
import { HighlightSearchComponent } from './highlight-search/highlight-search.component';
import { ServerConfigService } from './services/server-config.service';
import { SignInService } from './services/sign-in.service';
import { BreadcrumbComponent } from './views/breadcrumb/breadcrumb.component';
import { DbHeaderComponent } from './views/db-header/db-header.component';
import { LoginComponent } from './views/login/login.component';
import {
  PageTemplateSignedOutComponent
} from './views/page-template-signed-out/page-template-signed-out.component';
import { SurveyViewComponent } from './views/survey-view/survey-view.component';
import { SurveysComponent } from './views/surveys/surveys.component';
// Unfortunately stackdriver-errors-js doesn't properly declare dependencies, so
// we need to explicitly load its StackTrace dep:
// https://github.com/GoogleCloudPlatform/stackdriver-errors-js/issues/2
(<any>window).StackTrace = StackTrace;

import {ConfigService, DataBrowserService} from 'publicGenerated';
import { DbNoResultsComponent } from './components/db-no-results/db-no-results.component';
import { DbSpinnerComponent } from './components/db-spinner/db-spinner.component';
import { RecursiveTreeComponent } from './components/recursive-tree/recursive-tree.component';
import { SourceTreeComponent } from './components/source-tree/source-tree.component';
import { DbConfigService } from './utils/db-config.service';
import { TooltipService } from './utils/tooltip.service';
import { overriddenPublicUrlKey } from './views/app/app.component';
import { EhrViewComponent } from './views/ehr-view/ehr-view.component';
import { EmergencyComponent } from './views/emergency/emergency.component';
import { PhysicalMeasurementsComponent } from './views/pm/pm.component';
import { QuickSearchComponent } from './views/quick-search/quick-search.component';
import { SurveyChartComponent } from './views/survey-chart/survey-chart.component';

function getPublicBasePath() {
  return localStorage.getItem(overriddenPublicUrlKey) || environment.publicApiUrl;
}

// "Configuration" means Swagger API Client configuration.
export function getConfiguration(signInService: SignInService): Configuration {
  return new Configuration({
    basePath: getPublicBasePath(),
    accessToken: () => signInService.currentAccessToken
  });
}

export function getConfigService(http: Http) {
  return new ConfigService(http, getPublicBasePath(), null);
}

@NgModule({
  imports: [
    ApiModule,
    AppRoutingModule,
    BrowserModule,
    BrowserAnimationsModule,
    FormsModule,
    HttpModule,
    ReactiveFormsModule,
    ClarityModule,
    DataBrowserModule,
    ResponsiveModule.forRoot()
  ],
  declarations: [
    AppComponent,
    SurveysComponent,
    DbHeaderComponent,
    BreadcrumbComponent,
    SurveyViewComponent,
    HighlightSearchComponent,
    LoginComponent,
    QuickSearchComponent,
    EhrViewComponent,
    PageTemplateSignedOutComponent,
    PhysicalMeasurementsComponent,
    SurveyChartComponent,
    DbNoResultsComponent,
    DbSpinnerComponent,
    EmergencyComponent,
    SourceTreeComponent,
    RecursiveTreeComponent,
  ],
  providers: [
    {
      provide: ConfigService,
      useFactory: getConfigService,
      deps: [Http]
    },
    {
      provide: Configuration,
      deps: [SignInService],
      useFactory: getConfiguration
    },
    DbConfigService,
    TooltipService,
    ServerConfigService,
    {
      provide: ErrorHandler,
      deps: [ServerConfigService],
      useClass: ErrorReporterService,
    },
    SignInService,
  ],
  // This specifies the top-level components, to load first.
  bootstrap: [AppComponent]

})
export class AppModule {}
