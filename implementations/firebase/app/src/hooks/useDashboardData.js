import { useState, useEffect } from 'react';
import DataService from '../services/DataService';

const PAGE_SIZE = 1000;

function groupBy(records, field) {
  const groups = {};
  for (const r of records) {
    const key = r[field] || 'Unknown';
    groups[key] = (groups[key] || 0) + 1;
  }
  return groups;
}

function sumField(records, field) {
  return records.reduce((acc, r) => acc + (parseFloat(r[field]) || 0), 0);
}

function isThisWeek(dateStr) {
  if (!dateStr) return false;
  const d = new Date(dateStr);
  const now = new Date();
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay());
  startOfWeek.setHours(0, 0, 0, 0);
  return d >= startOfWeek;
}

function getLast7DaysBuckets(records, dateField) {
  const buckets = {};
  const now = new Date();
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    const key = d.toLocaleDateString('en-US', { weekday: 'short' });
    buckets[key] = 0;
  }
  for (const r of records) {
    if (!r[dateField]) continue;
    const d = new Date(r[dateField]);
    const diff = Math.floor((now - d) / (1000 * 60 * 60 * 24));
    if (diff >= 0 && diff < 7) {
      const key = d.toLocaleDateString('en-US', { weekday: 'short' });
      if (key in buckets) buckets[key]++;
    }
  }
  return Object.entries(buckets).map(([day, count]) => ({ day, count }));
}

export default function useDashboardData() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function fetchAll() {
      try {
        const [opps, leads, tickets, activities, invoices, quotations, ticketStatuses, pipelineStages, assets] = await Promise.all([
          DataService.list('Opportunity', { pageSize: PAGE_SIZE }),
          DataService.list('Lead', { pageSize: PAGE_SIZE }),
          DataService.list('Ticket', { pageSize: PAGE_SIZE }),
          DataService.list('Activity', { pageSize: PAGE_SIZE }),
          DataService.list('Invoice', { pageSize: PAGE_SIZE }),
          DataService.list('Quotation', { pageSize: PAGE_SIZE }),
          DataService.list('TicketStatus', { pageSize: PAGE_SIZE }),
          DataService.list('PipelineStage', { pageSize: PAGE_SIZE }),
          DataService.list('Asset', { pageSize: PAGE_SIZE }),
        ]);

        if (cancelled) return;

        // Build lookup maps for reference tables
        const closedStatusIds = new Set(ticketStatuses.filter((s) => s.is_closed).map((s) => s.id));
        const stageNameMap = {};
        for (const stage of pipelineStages) {
          stageNameMap[stage.id] = stage.name || stage.stage_name || 'Unknown';
        }

        // Opportunities
        const openOpps = opps.filter((o) => o.result === 'Open');
        const pipelineValue = sumField(openOpps, 'amount');
        const oppsByResult = groupBy(opps, 'result');

        // Group opportunities by resolved stage name
        const oppsByStage = {};
        for (const opp of opps) {
          const stageName = stageNameMap[opp.stage_id] || 'Unknown';
          oppsByStage[stageName] = (oppsByStage[stageName] || 0) + 1;
        }

        // Leads
        const leadsByStatus = groupBy(leads, 'status');
        const convertedLeads = leads.filter((l) => l.status === 'Converted').length;
        const leadConversionRate = leads.length > 0 ? Math.round((convertedLeads / leads.length) * 100) : 0;

        // Tickets — use TicketStatus lookup to determine open vs closed
        const ticketsByPriority = groupBy(tickets, 'priority');
        const openTickets = tickets.filter((t) => !closedStatusIds.has(t.status_id)).length;

        // Activities
        const activitiesByType = groupBy(activities, 'type');
        const activitiesThisWeek = activities.filter((a) => isThisWeek(a.created_at)).length;
        const activityTrend = getLast7DaysBuckets(activities, 'created_at');

        // Invoices
        const invoicesByStatus = groupBy(invoices, 'status');
        const invoiceRevenueByStatus = {};
        for (const inv of invoices) {
          const st = inv.status || 'Unknown';
          invoiceRevenueByStatus[st] = (invoiceRevenueByStatus[st] || 0) + (parseFloat(inv.total_amount) || 0);
        }

        // Quotations
        const quotationsByStatus = groupBy(quotations, 'status');

        setData({
          opportunities: {
            total: opps.length,
            open: openOpps.length,
            pipelineValue,
            byResult: oppsByResult,
            byStage: Object.entries(oppsByStage).map(([name, value]) => ({ name, value })),
          },
          leads: {
            total: leads.length,
            open: leads.filter((l) => !['Converted', 'Unqualified'].includes(l.status)).length,
            byStatus: leadsByStatus,
            conversionRate: leadConversionRate,
          },
          tickets: {
            total: tickets.length,
            open: openTickets,
            byPriority: Object.entries(ticketsByPriority).map(([name, value]) => ({ name, value })),
          },
          activities: {
            total: activities.length,
            thisWeek: activitiesThisWeek,
            byType: activitiesByType,
            trend: activityTrend,
          },
          invoices: {
            total: invoices.length,
            byStatus: invoicesByStatus,
            revenueByStatus: Object.entries(invoiceRevenueByStatus).map(([name, value]) => ({ name, value: Math.round(value) })),
          },
          quotations: {
            total: quotations.length,
            byStatus: quotationsByStatus,
          },
          assets: {
            total: assets.length,
            inactive: assets.filter((a) => a.status === 'Inactive').length,
          },
        });
      } catch (err) {
        console.error('Dashboard data fetch failed:', err);
        if (!cancelled) setData(null);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    fetchAll();
    return () => { cancelled = true; };
  }, []);

  return { data, loading };
}
