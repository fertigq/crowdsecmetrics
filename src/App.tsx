import React, { useState, useEffect } from 'react';
import { BarChart3, Shield, Activity, Server } from 'lucide-react';

interface Metric {
  reason: string;
  origin: string;
  action: string;
  count: number;
}

interface SystemMetrics {
  uptime: string;
  loadAverage: string;
  memory: {
    total: string;
    used: string;
    free: string;
  };
  disk: {
    total: string;
    used: string;
    available: string;
    usePercentage: string;
  };
}

function App() {
  const [metrics, setMetrics] = useState<Metric[]>([]);
  const [systemMetrics, setSystemMetrics] = useState<SystemMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [metricsResponse, systemResponse] = await Promise.all([
          fetch('http://localhost:3456/api/crowdsec-metrics'),
          fetch('http://localhost:3456/api/system-metrics')
        ]);

        if (!metricsResponse.ok || !systemResponse.ok) {
          throw new Error('Failed to fetch data');
        }

        const metricsData = await metricsResponse.json();
        const systemData = await systemResponse.json();

        setMetrics(metricsData);
        setSystemMetrics(systemData);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An error occurred');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 30000); // Refresh every 30 seconds

    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-lg text-center">
          <div className="text-red-500 text-xl mb-4">Error: {error}</div>
          <p className="text-gray-600">
            Please ensure the CrowdSec metrics server is running and accessible.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 p-6">
      <div className="max-w-7xl mx-auto">
        <header className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
            <Shield className="h-8 w-8 text-blue-500" />
            CrowdSec Metrics Dashboard
          </h1>
        </header>

        {/* System Metrics */}
        {systemMetrics && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div className="bg-white rounded-lg shadow-md p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-700">Uptime</h3>
                <Activity className="h-5 w-5 text-green-500" />
              </div>
              <p className="text-2xl font-bold text-gray-900">{systemMetrics.uptime}</p>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-700">Load Average</h3>
                <Server className="h-5 w-5 text-blue-500" />
              </div>
              <p className="text-2xl font-bold text-gray-900">{systemMetrics.loadAverage}</p>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-700">Memory Usage</h3>
                <BarChart3 className="h-5 w-5 text-purple-500" />
              </div>
              <p className="text-2xl font-bold text-gray-900">
                {systemMetrics.memory.used} / {systemMetrics.memory.total}
              </p>
              <p className="text-sm text-gray-500">Free: {systemMetrics.memory.free}</p>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-700">Disk Usage</h3>
                <Server className="h-5 w-5 text-yellow-500" />
              </div>
              <p className="text-2xl font-bold text-gray-900">
                {systemMetrics.disk.usePercentage}
              </p>
              <p className="text-sm text-gray-500">
                {systemMetrics.disk.used} / {systemMetrics.disk.total}
              </p>
            </div>
          </div>
        )}

        {/* CrowdSec Metrics */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Top Security Decisions</h2>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead>
                <tr>
                  <th className="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Reason
                  </th>
                  <th className="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Origin
                  </th>
                  <th className="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Action
                  </th>
                  <th className="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Count
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {metrics.map((metric, index) => (
                  <tr key={index} className={index % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {metric.reason}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {metric.origin}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {metric.action}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-blue-600">
                      {metric.count}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
