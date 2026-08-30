import HomePage from '../pages/HomePage';
import SettingsPage from '../pages/SettingsPage';
import ProfilePage from '../pages/ProfilePage';
import LeaderboardPage from '../pages/LeaderboardPage';
import PerformanceReviewPage from '../pages/PerformanceReviewPage';
import NotFoundPage from '../pages/NotFoundPage';
import ObjectListPage from '../pages/ObjectListPage';
import ObjectCreatePage from '../pages/ObjectCreatePage';
import ObjectDetailPage from '../pages/ObjectDetailPage';
import DealRoomPage from '../pages/DealRoomPage';
import CaseRoomPage from '../pages/CaseRoomPage';
import TeamTimelinePage from '../pages/TeamTimelinePage';
import MyTimelinePage from '../pages/MyTimelinePage';

const routes = [
  { path: '/', element: HomePage },
  { path: '/settings', element: SettingsPage },
  { path: '/profile', element: ProfilePage },
  { path: '/profile/:userId', element: PerformanceReviewPage },
  { path: '/leaderboard', element: LeaderboardPage },
  { path: '/my-timeline', element: MyTimelinePage },
  { path: '/team-timeline', element: TeamTimelinePage },
  { path: '/deal-rooms/:id', element: DealRoomPage },
  { path: '/case-rooms/:id', element: CaseRoomPage },
  { path: '/:objectType', element: ObjectListPage },
  { path: '/:objectType/new', element: ObjectCreatePage },
  { path: '/:objectType/:id', element: ObjectDetailPage },
  { path: '*', element: NotFoundPage },
];

export default routes;
