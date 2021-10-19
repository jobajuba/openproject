import { Query } from '@datorama/akita';
import { map, distinctUntilChanged } from 'rxjs/operators';
import {
  IAN_FACET_FILTERS,
  IanCenterState,
  IanCenterStore,
} from 'core-app/features/in-app-notifications/center/state/ian-center.store';
import {
  ApiV3ListFilter,
  Apiv3ListParameters,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { selectEntitiesFromIDCollection } from 'core-app/core/state/collection-store';

export class IanCenterQuery extends Query<IanCenterState> {
  activeFacet$ = this.select('activeFacet');

  notLoaded$ = this.select('notLoaded');

  paramsChanges$ = this.select(['params', 'activeFacet']);

  activeCollection$ = this.select('activeCollection');

  selectNotifications$ = this
    .activeCollection$
    .pipe(
      map((collection) => selectEntitiesFromIDCollection(this.resourceService, collection)),
      distinctUntilChanged(),
    );

  aggregatedCenterNotifications$ = this
    .selectNotifications$
    .pipe(
      map((notifications) => (
        _.groupBy(notifications, (notification) => notification._links.resource?.href || 'none')
      )),
      distinctUntilChanged(),
    );

  notifications$ = this
    .aggregatedCenterNotifications$
    .pipe(
      map((items) => Object.values(items)),
      distinctUntilChanged(),
    );

  hasNotifications$ = this
    .notifications$
    .pipe(
      map((items) => items.length > 0),
      distinctUntilChanged(),
    );

  hasMoreThanPageSize$ = this
    .notLoaded$
    .pipe(
      map((notLoaded) => notLoaded > 0),
    );

  get params():Apiv3ListParameters {
    const state = this.store.getValue();
    const hasFilters = state.filters.name && state.filters.filter;
    return {
      ...state.params,
      filters: [
        ...IAN_FACET_FILTERS[state.activeFacet],
        ...(hasFilters
          ? ([[state.filters.filter, '=', [state.filters.name]]] as ApiV3ListFilter[])
          : []
        ),
      ],
    };
  }

  constructor(
    protected store:IanCenterStore,
    protected resourceService:InAppNotificationsResourceService,
  ) {
    super(store);
  }
}