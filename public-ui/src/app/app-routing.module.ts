import { NgModule } from '@angular/core';
import { NavigationEnd, Router, RouterModule, Routes } from '@angular/router';
import { environment } from '../environments/environment';

import { SignInGuard } from './guards/sign-in-guard.service';
import { EhrViewComponent } from './views/ehr-view/ehr-view.component';
import { LoginComponent } from './views/login/login.component';
import { PhysicalMeasurementsComponent } from './views/pm/pm.component';
import { QuickSearchComponent } from './views/quick-search/quick-search.component';
import { SurveyViewComponent } from './views/survey-view/survey-view.component';
import { SurveysComponent } from './views/surveys/surveys.component';

declare let gtag: Function;

const routes: Routes = [
  {
    path: 'login',
    component: LoginComponent,
    data: { title: 'Sign In' }
  },
  {
    path: '',
    canActivate: [SignInGuard],
    canActivateChild: [SignInGuard],
    runGuardsAndResolvers: 'always',
    children: [
      {
        path: '',
        data: {
          title: 'Databrowser',
          breadcrumb: {
            value: 'Databrowser',
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
              value: 'survey: :id',
            }
          }
        },
        {
          path: 'ehr/:id',
          component: EhrViewComponent,
          data: {
            title: 'View Full Results',
            breadcrumb: {
              value: 'ehr: :id',
            }
          }
        }
        ]
      },

      // {
      //   path: 'quick-search/:dataType',
      //   component: QuickSearchComponent,
      //   data: { title: 'Quick Search' }
      // },
      {
        path: 'survey/:id',
        component: SurveyViewComponent,
        data: {
          title: 'View Survey Questions and Answers',
          breadcrumb: {
            value: 'survey',
            intermediate: false
          }
        }
      },
      {
        path: 'physical-measurements',
        component: PhysicalMeasurementsComponent,
        data: { title: 'Physical Measurements from Enrollment' }
      }
    ]
  },

];

@NgModule({
  imports: [RouterModule.forRoot(routes, { onSameUrlNavigation: 'reload' })],
  exports: [RouterModule],
  providers: [
    SignInGuard
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
