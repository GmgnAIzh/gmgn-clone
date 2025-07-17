import axios from 'axios';

export interface CryptoPair {
  id: string;
  symbol: string;
  name: string;
  current_price: number;
  price_change_percentage_24h: number;
  market_cap: number;
  total_volume: number;
}

export interface CandlestickData {
  time: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume?: number;
}

export interface PriceData {
  timestamp: number;
  price: number;
  volume: number;
}

class CryptoAPI {
  private baseURL = 'https://api.coingecko.com/api/v3';

  // 获取热门加密货币列表
  async getTopCryptos(limit: number = 10): Promise<CryptoPair[]> {
    try {
      const response = await axios.get(`${this.baseURL}/coins/markets`, {
        params: {
          vs_currency: 'usd',
          order: 'market_cap_desc',
          per_page: limit,
          page: 1,
          sparkline: false,
          price_change_percentage: '24h'
        }
      });
      return response.data;
    } catch (error) {
      console.error('Error fetching crypto data:', error);
      return this.getMockData();
    }
  }

  // 获取指定币种的历史价格数据
  async getHistoricalData(coinId: string, days: number = 7): Promise<CandlestickData[]> {
    try {
      const response = await axios.get(`${this.baseURL}/coins/${coinId}/ohlc`, {
        params: {
          vs_currency: 'usd',
          days: days
        }
      });

      return response.data.map((item: number[]) => ({
        time: item[0],
        open: item[1],
        high: item[2],
        low: item[3],
        close: item[4]
      }));
    } catch (error) {
      console.error('Error fetching historical data:', error);
      return this.getMockCandlestickData();
    }
  }

  // 获取实时价格数据
  async getRealTimePrice(coinId: string): Promise<PriceData | null> {
    try {
      const response = await axios.get(`${this.baseURL}/simple/price`, {
        params: {
          ids: coinId,
          vs_currencies: 'usd',
          include_24hr_vol: true,
          include_24hr_change: true
        }
      });

      const data = response.data[coinId];
      if (data) {
        return {
          timestamp: Date.now(),
          price: data.usd,
          volume: data.usd_24h_vol || 0
        };
      }
      return null;
    } catch (error) {
      console.error('Error fetching real-time price:', error);
      return null;
    }
  }

  // 模拟数据（当API失败时使用）
  private getMockData(): CryptoPair[] {
    return [
      {
        id: 'bitcoin',
        symbol: 'BTC',
        name: 'Bitcoin',
        current_price: 43250.00,
        price_change_percentage_24h: 2.34,
        market_cap: 847000000000,
        total_volume: 25000000000
      },
      {
        id: 'ethereum',
        symbol: 'ETH',
        name: 'Ethereum',
        current_price: 2580.00,
        price_change_percentage_24h: -1.23,
        market_cap: 310000000000,
        total_volume: 15000000000
      },
      {
        id: 'solana',
        symbol: 'SOL',
        name: 'Solana',
        current_price: 98.45,
        price_change_percentage_24h: 5.67,
        market_cap: 45000000000,
        total_volume: 3000000000
      },
      {
        id: 'cardano',
        symbol: 'ADA',
        name: 'Cardano',
        current_price: 0.47,
        price_change_percentage_24h: -2.1,
        market_cap: 16500000000,
        total_volume: 850000000
      },
      {
        id: 'dogecoin',
        symbol: 'DOGE',
        name: 'Dogecoin',
        current_price: 0.086,
        price_change_percentage_24h: 8.9,
        market_cap: 12300000000,
        total_volume: 1200000000
      }
    ];
  }

  private getMockCandlestickData(): CandlestickData[] {
    const now = Date.now();
    const data: CandlestickData[] = [];

    for (let i = 30; i >= 0; i--) {
      const time = now - (i * 24 * 60 * 60 * 1000); // 每天一个数据点
      const basePrice = 0.006 + Math.random() * 0.002;
      const open = basePrice + (Math.random() - 0.5) * 0.001;
      const close = open + (Math.random() - 0.5) * 0.002;
      const high = Math.max(open, close) + Math.random() * 0.001;
      const low = Math.min(open, close) - Math.random() * 0.001;

      data.push({
        time,
        open,
        high,
        low,
        close,
        volume: Math.random() * 1000000
      });
    }

    return data;
  }
}

export const cryptoAPI = new CryptoAPI();
