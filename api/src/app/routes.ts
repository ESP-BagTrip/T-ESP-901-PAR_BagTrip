import { Router } from 'express';
import travelRoutes from '../api/travel/travel.routes';
import authRoutes from '../api/auth/auth.routes';
import agentRoutes from '../api/agents/agent.routes';

export const routes = () => {
  const r = Router();
  r.use('/auth', authRoutes);
  r.use('/travel', travelRoutes);
  r.use('/agents', agentRoutes);
  return r;
};
