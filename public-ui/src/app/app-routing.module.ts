import { NgModule } from '@angular/core';
import { NavigationEnd, Router, RouterModule, Routes } from '@angular/router';
import { environment } from '../environments/environment';

import { IsSafeGuard } from './guards/is-safe-guard.service';
import { SignInGuard } from './guards/sign-in-guard.service';
import { EhrViewComponent } from './views/ehr-view/ehr-view.component';
import { EmergencyComponent } from './views/emergency/emergency.component';
import { LoginComponent } from './views/login/login.component';
import { PhysicalMeasurementsComponent } from './views/pm/pm.component';
import { QuickSearchComponent } from './views/quick-search/quick-search.component';
import { SurveyViewComponent } from './views/survey-view/survey-view.component';

declare let gtag: Function;

const routes: Routes = [
  {
    path: 'login',
    component: LoginComponent,
    data: { title: 'Sign In' }
  },
  {
    path: 'ehr',
    redirectTo: '',
    pathMatch: 'full'
  },
  {
    path: 'survey',
    redirectTo: '',
    pathMatch: 'full'
  },
  {
    path: 'error',
    pathMatch: 'full',
    component: EmergencyComponent,
    data: { title: 'ERROR' }
  },
  {
    path: '',
    canActivate: [SignInGuard, IsSafeGuard],
    canActivateChild: [SignInGuard, IsSafeGuard],
    runGuardsAndResolvers: 'always',
    children: [
      {
        path: '',
        data: {
          title: 'Data Browser',
          breadcrumb: {
            value: 'Data Browser',
          }
        },
        children: [{
          path: '',
          component: QuickSearchComponent,
        },
        {
          path: 'survey/:id',
          component: SurveyViewComponent,
          data: {
            title: 'View Survey Questions and Answers',
            breadcrumb: {
              value: ':id survey',
            }
          }
        },
        {
          path: 'ehr/:id',
          component: EhrViewComponent,
          data: {
            title: 'View Full Results',
            breadcrumb: {
              value: ':id Domain',
            }
          }
        },
        {
          path: 'physical-measurements',
          component: PhysicalMeasurementsComponent,
          data: {
            title: 'Physical Measurements from Enrollment',
            breadcrumb: {
              value: 'physical measurements'
            }
          }
        }
        ]
      }
    ]
  },

];

@NgModule({
  imports: [RouterModule.forRoot(routes, { onSameUrlNavigation: 'reload' })],
  exports: [RouterModule],
  providers: [
    SignInGuard,
    IsSafeGuard
  ]
})
export class AppRoutingModule {

  constructor(public router: Router) {
    this.router.events.subscribe(event => {
      if (event instanceof NavigationEnd) {
        gtag('config', environment.gaId, { 'page_path': event.urlAfterRedirects });
      }
    });
  }
}
