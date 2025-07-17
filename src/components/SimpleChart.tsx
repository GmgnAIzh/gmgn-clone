'use client';

import { useEffect, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';
import { cryptoAPI, CryptoPair } from '@/lib/cryptoAPI';
import { Button } from '@/components/ui/button';

interface Props {
  width?: number;
  height?: number;
}

const timeRanges = [
  { label: '1D', days: 1 },
  { label: '7D', days: 7 },
  { label: '30D', days: 30 },
  { label: '90D', days: 90 },
];

export default function SimpleChart({ width = 700, height = 350 }: Props) {
  const [cryptoList, setCryptoList] = useState<CryptoPair[]>([]);
  const [selectedCrypto, setSelectedCrypto] = useState<string>('bitcoin');
  const [selectedTimeRange, setSelectedTimeRange] = useState<number>(7);
  const [isLoading, setIsLoading] = useState(false);
  const [chartData, setChartData] = useState<Array<{
    time: string;
    price: number;
    volume: number;
    high: number;
    low: number;
    change: number;
  }>>([]);
  const [currentPrice, setCurrentPrice] = useState<number>(0);
  const [priceChange, setPriceChange] = useState<number>(0);
  const [mounted, setMounted] = useState(false);

  // 加载加密货币列表
  useEffect(() => {
    setMounted(true);
    const loadCryptoList = async () => {
      try {
        const data = await cryptoAPI.getTopCryptos(10);
        setCryptoList(data);
        if (data.length > 0) {
          setCurrentPrice(data[0].current_price);
          setPriceChange(data[0].price_change_percentage_24h);
        }
      } catch (error) {
        console.error('Failed to load crypto list:', error);
      }
    };

    loadCryptoList();
  }, []);

  // 加载历史数据
  useEffect(() => {
    const loadHistoricalData = async () => {
      setIsLoading(true);
      try {
        const data = await cryptoAPI.getHistoricalData(selectedCrypto, selectedTimeRange);

        const formattedData = data.map((item, index) => ({
          time: new Date(item.time).toLocaleDateString(),
          price: item.close,
          volume: item.volume || (item.close * 1000),
          high: item.high,
          low: item.low,
          change: index > 0 ? ((item.close - data[index - 1].close) / data[index - 1].close * 100) : 0
        }));

        setChartData(formattedData);

        if (data.length > 0) {
          const latestData = data[data.length - 1];
          setCurrentPrice(latestData.close);
        }

        const selectedCoin = cryptoList.find(coin => coin.id === selectedCrypto);
        if (selectedCoin) {
          setPriceChange(selectedCoin.price_change_percentage_24h);
        }

      } catch (error) {
        console.error('Failed to load historical data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    if (selectedCrypto) {
      loadHistoricalData();
    }
  }, [selectedCrypto, selectedTimeRange, cryptoList]);

  const formatPrice = (price: number): string => {
    if (price >= 1) {
      return `$${price.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    } else {
      return `$${price.toFixed(6)}`;
    }
  };

  const formatPercentage = (percentage: number): string => {
    const sign = percentage >= 0 ? '+' : '';
    return `${sign}${percentage.toFixed(2)}%`;
  };

  const CustomTooltip = ({ active, payload, label }: {
    active?: boolean;
    payload?: Array<{ value: number; dataKey: string }>;
    label?: string;
  }) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-gray-800 border border-gray-600 rounded p-3 shadow-lg">
          <p className="text-white text-sm">{`时间: ${label}`}</p>
          <p className="text-green-400 text-sm">
            {`价格: ${formatPrice(payload[0].value)}`}
          </p>
          {payload[1] && (
            <p className="text-blue-400 text-sm">
              {`成交量: ${payload[1].value.toFixed(0)}`}
            </p>
          )}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="bg-gray-800 rounded-lg p-4">
      {!mounted ? (
        <div className="flex items-center justify-center h-64">
          <div className="text-white">载入中...</div>
        </div>
      ) : (
        <>
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-4">
              <select
                value={selectedCrypto}
                onChange={(e) => setSelectedCrypto(e.target.value)}
                className="w-40 bg-gray-700 border border-gray-600 text-white rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#beeb26]"
              >
                {cryptoList.map((crypto) => (
                  <option key={crypto.id} value={crypto.id}>
                    {crypto.symbol} - {crypto.name}
                  </option>
                ))}
              </select>

              <div>
                <div className="text-white text-xl font-bold">
                  {formatPrice(currentPrice)}
                </div>
                <div className={`text-sm ${priceChange >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                  {formatPercentage(priceChange)}
                </div>
              </div>
            </div>

            <div className="flex space-x-2">
              {timeRanges.map((range) => (
                <Button
                  key={range.days}
                  variant={selectedTimeRange === range.days ? "default" : "ghost"}
                  size="sm"
                  className={`${
                    selectedTimeRange === range.days
                      ? 'bg-[#beeb26] text-black hover:bg-[#a5d423]'
                      : 'text-gray-400 hover:text-white hover:bg-gray-700'
                  }`}
                  onClick={() => setSelectedTimeRange(range.days)}
                  disabled={isLoading}
                >
                  {range.label}
                </Button>
              ))}
            </div>
          </div>

          <div className="relative" style={{ width, height }}>
            {isLoading && (
              <div className="absolute inset-0 bg-gray-800 bg-opacity-50 flex items-center justify-center z-10">
                <div className="text-white">载入中...</div>
              </div>
            )}

            <div className="mb-4">
              <ResponsiveContainer width="100%" height={height * 0.7}>
                <LineChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                  <XAxis
                    dataKey="time"
                    stroke="#9ca3af"
                    fontSize={12}
                  />
                  <YAxis
                    stroke="#9ca3af"
                    fontSize={12}
                    tickFormatter={(value) => formatPrice(value)}
                  />
                  <Tooltip content={<CustomTooltip />} />
                  <Line
                    type="monotone"
                    dataKey="price"
                    stroke="#10b981"
                    strokeWidth={2}
                    dot={false}
                    activeDot={{ r: 4, fill: '#10b981' }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>

            <div>
              <ResponsiveContainer width="100%" height={height * 0.25}>
                <BarChart data={chartData}>
                  <XAxis dataKey="time" hide />
                  <YAxis hide />
                  <Tooltip content={<CustomTooltip />} />
                  <Bar
                    dataKey="volume"
                    fill="#6b7280"
                    opacity={0.6}
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="mt-2 text-xs text-gray-400 flex justify-between">
            <span>点击图表进行交互</span>
            <span>数据来源: CoinGecko</span>
          </div>
        </>
      )}
    </div>
  );
}
