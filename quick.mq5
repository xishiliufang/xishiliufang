//+------------------------------------------------------------------+
//|                                                        quick.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\trade.mqh>
#include <Trade\PositionInfo.mqh>
CTrade trade;

string baseMagic = 15979045641;
datetime closeTime;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   string moneyPair = Symbol();
   ENUM_TIMEFRAMES timeFrames = Period();
//baseMagic = baseMagic + moneyPair + timeFrames;
   loginfo(baseMagic);
   EventSetTimer(60);
   Comment("Spread = ",SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
   EventKillTimer();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   double open[];
   double high[];
   double low[];
   double close[];
   initK(open,high,low,close);
   bool buySingle = geBuySingle(open,high,low,close);
   bool sellSingle = getSellSingle(open,high,low,close);
   if(buySingle & !hasBuyPosition() & !hasBuyOrder() ) {
      sendRandomPendingOrder(getOpenLots2(1),high[1],low[0],0,getTimes(getEquitionTime()));
   } else if(sellSingle & !hasSellPosition()  & !hasSellOrder()) {
      sendRandomPendingOrder(getOpenLots2(2),low[1],high[0],1,getTimes(getEquitionTime()));
   }
//平仓
//modifyTest2(getModifyPrice());
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade() {
//---
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
//---
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool geBuySingle(double &open[],double &high[],double &low[],double &close[]) {
   bool a = (open[1] < close[1]) & (open[2] > close[2]) & (high[1] < high[2]) & (high[2] < high[3]) & (low[1] < low[2]) & (low[2] < low[3]);
   bool b = (open[1] < close[1]) & (open[2] > close[2]) & (high[1] <= high[2]) & (low[1] >= low[2]);
   return a || b;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool getSellSingle(double &open[],double &high[],double &low[],double &close[]) {
   bool a = (open[1] > close[1]) & (open[2] < close[2]) & (high[1] > high[2]) & (high[2] > high[3]) & (low[1] > low[2]) & (low[2] > low[3]);
   bool b = (open[1] > close[1]) & (open[2] < close[2]) & (high[1] <= high[2]) & (low[1] >= low[2]);
   return a || b;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void initK(double &open[],double &high[],double &low[],double &close[]) {
   initOpen(open);
   initHigh(high);
   initLow(low);
   initClose(close);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void initOpen(double &array[]) {
   ArraySetAsSeries(array,true);
   CopyOpen(Symbol(),0,0,4,array);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void initHigh(double &array[]) {
   ArraySetAsSeries(array,true);
   CopyHigh(Symbol(),0,0,4,array);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void initLow(double &array[]) {
   ArraySetAsSeries(array,true);
   CopyLow(Symbol(),0,0,4,array);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void initClose(double &array[]) {
   ArraySetAsSeries(array,true);
   CopyClose(Symbol(),0,0,4,array);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int sendRandomPendingOrder(double lots,double price,double stopPrice,int orderType,datetime expiration) {
   printf("stop-->:" + NormalizeDouble(stopPrice,Digits()));
   printf("price-->:" + NormalizeDouble(stopPrice,Digits()));
   if(NormalizeDouble(stopPrice,Digits()) == NormalizeDouble(price,Digits())) {
      return -1;
   }
//--- 准备请求
//int i=SendRandomPendingOrder(0.01,1.18172,1.18500,1,"2021.07.15 17:45:00");
   MqlTradeRequest request = {};
// 在制定环境下执行放置交易命令（待办订单）
   request.action = TRADE_ACTION_PENDING;
   request.magic = 1045518847;
   request.symbol = Symbol();
   request.volume = lots;
   request.sl = stopPrice;
   request.type_time = ORDER_TIME_SPECIFIED;
//request.expiration=D'2021.07.15 16:50:00';
   request.expiration = expiration;
// 没有指定盈利价位
//request.tp = 0;
   if(orderType == 0) {
      double tp = NormalizeDouble((price - stopPrice) / 2,Digits());
      request.type = ORDER_TYPE_BUY_STOP;
      request.tp = price + tp;
   } else if(orderType == 1) {
      double tp = NormalizeDouble((stopPrice - price) / 2,Digits());
      request.type = ORDER_TYPE_SELL_STOP;
      request.tp = price - tp;
   }
   request.price = price;
//--- 发送交易请求
   MqlTradeResult result = {};
   OrderSend(request,result);
   MqlRates mqlRates[];
   ArraySetAsSeries(mqlRates,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,100,mqlRates);
   long expritionTime = (long)mqlRates[0].time - (long)mqlRates[1].time;
   closeTime = mqlRates[1].time + expritionTime * 2;
   Print(123456, ";",orderType, ";",price, ";",lots,";",stopPrice);
   printf(expritionTime * 2);
   printf(closeTime);
//--- 编写服务器回复到日志
   Print(__FUNCTION__,":",result.comment);
   if(result.retcode == 10016) Print(result.bid,result.ask,result.price);
//--- 返回交易服务器回复的代码
   return result.retcode;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAll() {
   ulong ticket = 0;
   int total = PositionsTotal();
   if(total <= 0)return;
   for(int i = total - 1; i >= 0; i--) {
      if((ticket = PositionGetTicket(i)) > 0) {
         if((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) || (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)) {
            trade.PositionClose(ticket);
         }
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool getCloseSingle() {
   MqlRates mqlRates[];
   ArraySetAsSeries(mqlRates,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,100,mqlRates);
   long expritionTime = (long)mqlRates[0].time - (long)mqlRates[1].time;
//datetime closeTime=mqlRates[1].time+expritionTime*2;
   if(closeTime == TimeCurrent()) {
      printf(closeTime == TimeCurrent());
      return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getModifyPrice() {
   MqlRates mqlRates[];
   ArraySetAsSeries(mqlRates,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,100,mqlRates);
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(type == POSITION_TYPE_BUY) {
      return mqlRates[1].low - 0.00005;
   }
   return mqlRates[1].high + 0.00005;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getOpenLots() {
   MqlRates mqlRates[];
   ArraySetAsSeries(mqlRates,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,100,mqlRates);
   double hl = mqlRates[1].high - mqlRates[1].low;
   double math = NormalizeDouble(hl,Digits());
//1手止损$
   double stopmoney = math * 100000;
   double stopMoneyOnePercent = AccountInfoDouble(ACCOUNT_BALANCE) * 0.01;
   double lots = NormalizeDouble(stopMoneyOnePercent / stopmoney,2);
   if(lots < 0.01) {
      lots = 0.01;
   }
   return lots;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getOpenLots2(int type) {
   MqlRates mqlRates[];
   ArraySetAsSeries(mqlRates,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,100,mqlRates);
   double hl = 0.0;
   if(type == 1) {
      //buy
      double h1 = mqlRates[1].high - mqlRates[0].low;
   } else if(type == 2) {
      //sell
      double h1 = mqlRates[1].low - mqlRates[0].high;
   }
   double math = NormalizeDouble(hl,Digits());
//1手止损$
   double stopmoney = math * 100000;
   double stopMoneyOnePercent = AccountInfoDouble(ACCOUNT_BALANCE) * 0.01;
   if(stopmoney <= 0) {
      return 0.01;
   }
   double lots = NormalizeDouble(stopMoneyOnePercent / stopmoney,2);
   if(lots < 0.01) {
      lots = 0.01;
   }
   return lots;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime getTimes(int times) {
//datetime time=getTimes(60*60);
//   printf("start time-->"+time);
// SendRandomPendingOrder(0.01,1.17590,0,1,time);
   MqlRates mqlRates[];
   ArraySetAsSeries(mqlRates,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,100,mqlRates);
//向前推1小时
// Print(mqlRates[0].time+";"+(mqlRates[0].time-3600));
//秒(long)mqlRates[0].time-(long)mqlRates[1].time
//Print();
   return mqlRates[0].time + times;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long getEquitionTime() {
   MqlRates mqlRates[];
   ArraySetAsSeries(mqlRates,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,100,mqlRates);
   long equition = (long)mqlRates[0].time - (long)mqlRates[1].time;
   return equition;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void loginfo(string info) {
   Print(info);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void loginfo(int info) {
   Print(info);
}
//+------------------------------------------------------------------+
void modifyTest2(double stop) {
//--- 声明并初始化交易请求和交易请求结果
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total = PositionsTotal(); // 持仓数
//--- 重做所有持仓
   for(int i = 0; i < total; i++) {
      //--- 订单的参数
      ulong  position_ticket = PositionGetTicket(i); // 持仓价格
      string position_symbol = PositionGetString(POSITION_SYMBOL); // 交易品种
      int    digits = (int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); // 小数位数
      ulong  magic = PositionGetInteger(POSITION_MAGIC); // 持仓的幻数
      double volume = PositionGetDouble(POSITION_VOLUME);  // 持仓交易量
      double sl = PositionGetDouble(POSITION_SL); // 持仓止损
      double tp = PositionGetDouble(POSITION_TP); // 持仓止赢
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); // type of the position
      //--- 输出持仓信息
      PrintFormat("#%I64u %s  %s  %.2f  %s  sl: %s  tp: %s  [%I64d]",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  DoubleToString(sl,digits),
                  DoubleToString(tp,digits),
                  magic);
      //--- 如果幻数匹配，不定义止损和止赢magic==EXPERT_MAGIC
      if(sl != stop) {
         //--- 计算当前价格水平
         double price = PositionGetDouble(POSITION_PRICE_OPEN);
         double bid = SymbolInfoDouble(position_symbol,SYMBOL_BID);
         double ask = SymbolInfoDouble(position_symbol,SYMBOL_ASK);
         int    stop_level = (int)SymbolInfoInteger(position_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         double price_level;
         //--- 如果最小值被接受，那么当前平仓价的点数偏距不设置
         if(stop_level <= 0)
            stop_level = 150; // 设置当前平仓价的150点偏距
         else
            stop_level += 50; // 为了可靠性而设置偏距到(SYMBOL_TRADE_STOPS_LEVEL + 50) 点
         //--- 计算并凑整止损和止赢值
         price_level = stop_level * SymbolInfoDouble(position_symbol,SYMBOL_POINT);
         if(type == POSITION_TYPE_BUY) {
            sl = NormalizeDouble(bid - price_level,digits);
            //tp=NormalizeDouble(ask+price_level,digits);
         } else {
            sl = NormalizeDouble(ask + price_level,digits);
            //tp=NormalizeDouble(bid-price_level,digits);
         }
         //--- 归零请求和结果值
         ZeroMemory(request);
         ZeroMemory(result);
         //--- 设置操作参数
         request.action  = TRADE_ACTION_SLTP; // 交易操作类型
         request.position = position_ticket; // 持仓价格
         request.symbol = position_symbol;   // 交易品种
         request.sl      = stop;               // 持仓止损
         request.tp      = tp;               // 持仓止赢
         request.magic = baseMagic;       // 持仓的幻数
         //--- 输出更改信息
         PrintFormat("Modify #%I64d %s %s",position_ticket,position_symbol,EnumToString(type));
         //--- 发送请求
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());  // 如果不能发送请求，输出错误代码
         //--- 操作信息
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hasBuyPosition() {
   int total = PositionsTotal(); // 持仓数
//--- 重做所有持仓
   for(int i = total - 1; i >= 0; i--) {
      //--- 订单的参数
      ulong  position_ticket = PositionGetTicket(i);                                    // 持仓价格
      string position_symbol = PositionGetString(POSITION_SYMBOL);                      // 交易品种
      int    digits = (int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);            // 小数位数
      ulong  magic = PositionGetInteger(POSITION_MAGIC);                                // 持仓的幻数
      double volume = PositionGetDouble(POSITION_VOLUME);                               // 持仓交易量
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // 持仓类型
      //--- 输出持仓信息
      /*PrintFormat("#%I64u %s  %s  %.2f  %s [%I64d]",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  magic);*/
      if(EnumToString(type) == "POSITION_TYPE_BUY") {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hasSellPosition() {
   int total = PositionsTotal(); // 持仓数
//--- 重做所有持仓
   for(int i = total - 1; i >= 0; i--) {
      //--- 订单的参数
      ulong  position_ticket = PositionGetTicket(i);                                    // 持仓价格
      string position_symbol = PositionGetString(POSITION_SYMBOL);                      // 交易品种
      int    digits = (int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);            // 小数位数
      ulong  magic = PositionGetInteger(POSITION_MAGIC);                                // 持仓的幻数
      double volume = PositionGetDouble(POSITION_VOLUME);                               // 持仓交易量
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // 持仓类型
      //--- 输出持仓信息
      /*PrintFormat("#%I64u %s  %s  %.2f  %s [%I64d]",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  magic);*/
      if(EnumToString(type) == "POSITION_TYPE_SELL") {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
bool hasBuyOrder() {
//--- 订单属性返回值的变量
   ulong    ticket;
   double   open_price;
   double   initial_volume;
   datetime time_setup;
   string   symbol;
   string   type;
   long     order_magic;
//--- 当前挂单量
   uint     total = OrdersTotal();
//--- 反复检查通过订单
   for(uint i = 0; i < total; i++) {
      //--- 通过列表中的仓位返回订单报价
      if(ticket = OrderGetTicket(i)) {
         //--- 返回订单属性
         open_price    = OrderGetDouble(ORDER_PRICE_OPEN);
         time_setup    = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
         symbol        = OrderGetString(ORDER_SYMBOL);
         order_magic   = OrderGetInteger(ORDER_MAGIC);
         //positionID    = OrderGetInteger(ORDER_POSITION_ID);
         initial_volume = OrderGetDouble(ORDER_VOLUME_INITIAL);
         type          = EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE)));
         //--- 准备和显示订单信息
         /*printf("#ticket %d %s %G %s at %G was set up at %s",
                ticket,                 // 订单报价
                type,                   // 类型
                initial_volume,         // 已下交易量
                symbol,                 // 交易品种
                open_price,             // 规定的开盘价
                TimeToString(time_setup)// 下订单时间
               );
               */
         if(type == "ORDER_TYPE_BUY_STOP") {
            return true;
         }
      }
   }
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hasSellOrder() {
//--- 订单属性返回值的变量
   ulong    ticket;
   double   open_price;
   double   initial_volume;
   datetime time_setup;
   string   symbol;
   string   type;
   long     order_magic;
//--- 当前挂单量
   uint     total = OrdersTotal();
//--- 反复检查通过订单
   for(uint i = 0; i < total; i++) {
      //--- 通过列表中的仓位返回订单报价
      if(ticket = OrderGetTicket(i)) {
         //--- 返回订单属性
         open_price    = OrderGetDouble(ORDER_PRICE_OPEN);
         time_setup    = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
         symbol        = OrderGetString(ORDER_SYMBOL);
         order_magic   = OrderGetInteger(ORDER_MAGIC);
         //positionID    = OrderGetInteger(ORDER_POSITION_ID);
         initial_volume = OrderGetDouble(ORDER_VOLUME_INITIAL);
         type          = EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE)));
         //--- 准备和显示订单信息
         /*printf("#ticket %d %s %G %s at %G was set up at %s",
                ticket,                 // 订单报价
                type,                   // 类型
                initial_volume,         // 已下交易量
                symbol,                 // 交易品种
                open_price,             // 规定的开盘价
                TimeToString(time_setup)// 下订单时间
               );
               */
         if(type == "ORDER_TYPE_SELL_STOP") {
            return true;
         }
      }
   }
   return false;
}
//+------------------------------------------------------------------+
