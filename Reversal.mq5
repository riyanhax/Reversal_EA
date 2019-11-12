//+------------------------------------------------------------------+
//|                                                     Reversal.mq5 |
//|                                             Copyright 2019, ADCM |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright     "ADCM"
#property version       "1.00"
#property strict

int shift = 1; //The shift used by this indicator
int handle_icustom;

//--- input parameters
input    string   stub1 = "========Indicator Settings========";               //========Indicator Settings========
input    string   pathToIndicator = "Market\\PipFinite_Reversal_PRO_MT5";     // Path to indicator
input    int      signalPeriod = 2;                                           // Signal Period
input    int      zonePeriod = 5;                                             // Zone Period
input    double   zoneDeviation = 1.45;                                       // Zone Deviation
input    int      stoplossMode = 3;                                           // Stop Loss Selection
input    int      stoplossOffset = 20;                                        // Stop Loss Offset(Points)
input    double   takeProfitFactor = 2.5;                                     // Take Profit Factor
input    int      lookback = 3000;                                            // Maximum History Bars
input    string   stub2 = "========Additional Settings========";              //========Additional Settings========
input    int      succsessRateForOpenTrade = 75;                              // Succsess Rate For Open Trade
input    int      expertMagicNumber = 1;                                      // Expert Magic Number
input    double   orderVolume = 0.1;                                          // Order volume
input    string   comment = "EURUSD_M15";                                     // Comment
input    bool     useTp2 = false;                                             // Use TP2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//Load EX5
   handle_icustom = iCustom(Symbol(), PERIOD_CURRENT, pathToIndicator, " ",
                            signalPeriod, zonePeriod, zoneDeviation, stoplossMode, stoplossOffset, takeProfitFactor, lookback);

//--- Нужно проверить, не были ли возвращены значения Invalid Handle
   if(handle_icustom<0)
     {
      Alert("Ошибка при создании индикаторов - номер ошибки: ",GetLastError(),"!!");
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Достаточно ли количество баров для работы

       /*
      if(Bars(_Symbol,_Period)<lookback) // общее количество баров на графике меньше lookback?
        {
         Alert("На графике меньше " + IntegerToString(lookback) + " баров (" + IntegerToString(Bars(_Symbol,_Period)) + "), советник не будет работать!!");
         return;
        }
        */

// Для сохранения значения времени бара мы используем static-переменную oldTimeBar.
// При каждом выполнении функции OnTick мы будем сравнивать время текущего бара с сохраненным временем.
// Если они не равны, это означает, что начал строится новый бар.

   static datetime oldTime;
   datetime newTime[1];
   bool isNewBar=false;

// копируем время текущего бара в элемент New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,newTime);
   if(copied>0) // ok, успешно скопировано
     {
      if(oldTime!=newTime[0]) //if oldTime not equals
        {
         isNewBar = true;   // new bar set to true
         if(MQL5InfoInteger(MQL5_DEBUGGING))
            Print("Новый бар",newTime[0],"старый бар",oldTime);
         oldTime=newTime[0];   // save bar time
        }
     }
   else
     {
      Alert("Ошибка копирования времени, номер ошибки = ",GetLastError());
      ResetLastError();
      return;
     }

//--- Opening trades only on new bar. Filter already getted signals
   if(isNewBar==false)
     {
      return;
     }

   double succsessRateFromIndicator = GetIndicatorValue(31); //Success Rate% (31)
   double takeProfit1 = GetIndicatorValue(9);        //TP1 Price (9)
   double takeProfit2 = GetIndicatorValue(10);        //TP2 Price (10)
   double stopLoss = GetIndicatorValue(11);          //SL Price (11)

   if((GetIndicatorValue(7) > 0) && (succsessRateFromIndicator >= succsessRateForOpenTrade)) //Buy Signal (7)
     {
      MqlTradeResult orderResult = openOrder(ORDER_TYPE_BUY, orderVolume, expertMagicNumber, takeProfit1, stopLoss, comment);
     }

   if((GetIndicatorValue(8) > 0) && (succsessRateFromIndicator >= succsessRateForOpenTrade)) //Sell Signal (8)
     {
      MqlTradeResult orderResult = openOrder(ORDER_TYPE_SELL, orderVolume, expertMagicNumber, takeProfit1, stopLoss, comment);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTrade()
  {


  }

//+------------------------------------------------------------------+
//| Get indicator values based on buffer number.                     |
//+------------------------------------------------------------------+
double GetIndicatorValue(int buffer)
  {
   if(shift < 0)
      return(NULL);
   double Arr[1];
   if(CopyBuffer(handle_icustom,buffer,shift,1,Arr)>0)
     {
      return(Arr[0]);
     }
   return(NULL);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MqlTradeResult openOrder(ENUM_ORDER_TYPE orderType, double volume, int magicNumber, double takeProfit, double stopLoss, string orderComment)
  {
   MqlTradeRequest requestOrder = {0};
   MqlTradeResult responseOrder = {0};
   requestOrder.action      = TRADE_ACTION_DEAL;
   requestOrder.symbol      = Symbol();
   requestOrder.volume      = volume;
   requestOrder.type        = orderType;
   requestOrder.price       = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   requestOrder.deviation   = 10;
   requestOrder.magic       = magicNumber;
   requestOrder.sl          = stopLoss;
   requestOrder.tp          = takeProfit;
   requestOrder.comment     = orderComment;

   if(!OrderSend(requestOrder, responseOrder))
     {
      PrintFormat("OrderSend ERROR %d", GetLastError());
     }
   return responseOrder;
  }
//+------------------------------------------------------------------+
