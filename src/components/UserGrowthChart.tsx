import React, { useState } from 'react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

interface ChartData {
  day: string;
  count: number;
}

interface UserGrowthChartProps {
  data?: ChartData[];
  bwMode?: boolean; // if true, draw in black & white
}

function CustomTooltip({ label, payload }: any) {
  if (!payload || !payload.length) return null;
  
  const dateObj = new Date(label);
  const month = (dateObj.getMonth() + 1).toString().padStart(2, '0');
  const day = dateObj.getDate().toString().padStart(2, '0');
  const year = dateObj.getFullYear();
  const formattedDate = `${month}-${day}-${year}`;
  
  return (
    <div className="bg-white text-black border border-gray-300 rounded p-2 text-sm pointer-events-none">
      <div>Users: {payload[0].value}</div>
      <div>{formattedDate}</div>
    </div>
  );
}

export const UserGrowthChart: React.FC<UserGrowthChartProps> = ({
  data = [],
  bwMode = false,
}) => {
  const [pos, setPos] = useState<{ x: number; y: number }>({ x: 0, y: 0 });

  // If bwMode => black stroke, black fill. Otherwise we do normal style.
  const strokeColor = bwMode ? '#000000' : '#1E3A8A';
  const fillId = bwMode ? 'colorFillBW' : 'colorFill';

  return (
    <div style={{ width: '100%', height: 300, padding: 0, margin: 0 }}>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart
          data={data}
          margin={{ top: 0, right: 0, left: 0, bottom: 0 }}
          onMouseMove={(st) => {
            if (st.isTooltipActive && st.chartX && st.chartY) {
              setPos({ x: st.chartX, y: st.chartY });
            } else {
              setPos({ x: 0, y: 0 });
            }
          }}
        >
          <defs>
            <linearGradient id="colorFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#1E3A8A" stopOpacity={0.8} />
              <stop offset="100%" stopColor="#1E3A8A" stopOpacity={0.1} />
            </linearGradient>
            <linearGradient id="colorFillBW" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#000000" stopOpacity={0.7} />
              <stop offset="100%" stopColor="#000000" stopOpacity={0.1} />
            </linearGradient>
          </defs>

          <CartesianGrid
            horizontal={false}
            vertical={true}
            strokeDasharray="3 3"
            stroke="#ccc"
          />
          <XAxis hide={true} dataKey="day" />
          <YAxis hide={true} domain={[0, 'dataMax']} />

          <Tooltip
            cursor={false}
            position={pos}
            isAnimationActive={false}
            wrapperStyle={{ pointerEvents: 'none' }}
            content={<CustomTooltip />}
          />

          <Area
            type="monotone"
            dataKey="count"
            stroke={strokeColor}
            strokeWidth={2}
            fill={`url(#${fillId})`}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
};