# 本程序描述在R中对影子银行建模，并对模型进行分析和研究。
# 首先加载需要用到的R包。R包是一些工具的集合，方便重复使用。
# 这个包可以读取Excel表格文件。
library(gdata)
# 这个包有工具函数处理时间序列。
library(TTR)
# 这个包可以进行单位根检验。
library(fUnitRoots)
library(urca)
# 这个包可以进行ARIMA建模。
library(forecast)
# 这个包做Engle-Granger测试。
library(egcm)
# 这个包做Granger因果检验。
library(vars)
# 这个包有工具处理时间序列。
library(xts)
#library(mts)
# 这个包方便输出内容。
library(knitr)
# 首先读取xls文件，文件中包含了可能影响影子银行的各种因素，接下来我们会基于这些数据建立影子银行的模型。文件的最开始两行是文件头，说明了每个列的名字，跳过最开始的两行。
raw_data <- read.xls("data.xls", sheet = 1, skip=2)
# 文件中有一些列是隐藏的，但是R会把隐藏的列也读出来，因此我们重新设置列的名字，方便后面读取列。
# 第一列是对应年月改名为MONTH，第二列是用X12加法季节性调整后的LNSB，第三列是X12（乘法）季节性调整后的DLNM2，第四列是规模以上工业企业增加值当月同比实际增速，第五列是CPI指数，第六列是当月银行间同业拆借加权平均利率
colnames(raw_data) = c("MONTH", "X", "X.1", "LNSB", "X.2", "X.3", "X.4", "DLNM2", "GYZS", "CPI", "SHIBOR")
# 将第一列转换为日期，默认是字符。转换为日期后可以用于后面创建时间序列。
raw_data <- raw_data[c("MONTH", "LNSB", "DLNM2", "GYZS", "CPI", "SHIBOR")]
raw_data <- read.zoo(raw_data, FUN=as.yearmon)
# 数据的图形表示。
n <- c("LNSB", "DLNM2", "GYZS", "CPI", "SHIBOR")
for (c in n) {
  plot.xts(raw_data[, c])
}

# 数据的描述性统计特性。
kable(summary(raw_data))

# 创建表格用于存储每个变量的平稳性检验的结果。我们会对变量以及变量的一阶差分做ADF检验。
var_adf_test_result <- data.frame(name=c("LNSB", "DLNM2", "GYZS", "CPI", "SHIBOR"),
                                  adf=rep(0, 5),
                                  diff_adf=rep(0, 5),
                                  type=c("(c, 0, 0)", "(c, 0, 0)", "(c, 0, 0)", "(c, 0, 0)", "(c, 0, 0)"),
                                  result=c("0 (0)", "0 (0)", "0 (0)", "0 (0)", "0 (0)"),
                                  stringsAsFactors=FALSE)
# 对LNSB变量进行平稳性检验。创建该变量的时间序列。并且对该时间序列进行adf检测，允许常数，不允许时间趋势，并且没有滞后期阶数。
series <- as.ts(raw_data[, "LNSB"])
result <- adfTest(series, type = "c")
show(result)
lnsb.df <- ur.df(as.vector(raw_data[, "LNSB"]))
summary(lnsb.df)

# 对LNSB的一阶差分序列做同样的检验。
diff_series <- diff(series, lag=1)
diff_result <- adfTest(diff_series, type = "c")
hypothesis = paste(ifelse(result@test$p.value <= 0.05, "1", "0"),
                   ifelse(diff_result@test$p.value <= 0.05, "(1)", "(0)"),
                   sep=" ")
# 保存结果。
var_adf_test_result[1, c("adf", "diff_adf", "result")] <- c(result@test$statistic, diff_result@test$statistic, hypothesis)
# 检验DLNM2
series <- as.ts(raw_data[, "DLNM2"])
result <- adfTest(series, type = "c")
diff_series <- diff(series, lag=1)
diff_result <- adfTest(diff_series, type = "c")
hypothesis = paste(ifelse(result@test$p.value <= 0.05, "1", "0"),
                   ifelse(diff_result@test$p.value <= 0.05, "(1)", "(0)"),
                   sep=" ")
var_adf_test_result[2, c("adf", "diff_adf", "result")] <- c(result@test$statistic, diff_result@test$statistic, hypothesis)
# 检验GYZS
series <- as.ts(raw_data[, "GYZS"])
result <- adfTest(series, type = "c")
diff_series <- diff(series, lag=1)
diff_result <- adfTest(diff_series, type = "c")
hypothesis = paste(ifelse(result@test$p.value <= 0.05, "1", "0"),
                   ifelse(diff_result@test$p.value <= 0.05, "(1)", "(0)"),
                   sep=" ")
var_adf_test_result[3, c("adf", "diff_adf", "result")] <- c(result@test$statistic, diff_result@test$statistic, hypothesis)

# 检验CPI
series <- as.ts(raw_data[, "CPI"])
result <- adfTest(series, type = "c")
diff_series <- diff(series, lag=1)
diff_result <- adfTest(diff_series, type = "c")
hypothesis = paste(ifelse(result@test$p.value <= 0.05, "1", "0"),
                   ifelse(diff_result@test$p.value <= 0.05, "(1)", "(0)"),
                   sep=" ")
var_adf_test_result[4, c("adf", "diff_adf", "result")] <- c(result@test$statistic, diff_result@test$statistic, hypothesis)

# 检验SHIBOR
series <- as.ts(raw_data[, "SHIBOR"])
result <- adfTest(series, type = "c")
diff_series <- diff(series, lag=1)
diff_result <- adfTest(diff_series, type = "c")
hypothesis = paste(ifelse(result@test$p.value <= 0.05, "1", "0"),
                   ifelse(diff_result@test$p.value <= 0.05, "(1)", "(0)"),
                   sep=" ")
var_adf_test_result[5, c("adf", "diff_adf", "result")] <- c(result@test$statistic, diff_result@test$statistic, hypothesis)

# 这是对所有变量进行平稳性分析后的结果，显著性水平设置为5%。
colnames(var_adf_test_result) = c("变量", "ADF检验值", "一阶差分ADF检验值", "检验类型", "结论")
kable(var_adf_test_result, digits=4)

# 下面我们对变量LNSB,和其他变量进行协整检验。
plot(egcm(as.vector(raw_data[, "LNSB"]), as.vector(raw_data[, "DLNM2"])))
plot(egcm(as.vector(raw_data[, "LNSB"]), as.vector(raw_data[, "GYZS"])))
plot(egcm(as.vector(raw_data[, "LNSB"]), as.vector(raw_data[, "CPI"])))
plot(egcm(as.vector(raw_data[, "LNSB"]), as.vector(raw_data[, "SHIBOR"])))

# 对变量DLNM2和其他变量进行协整检验。
plot(egcm(as.vector(raw_data[, "DLNM2"]), as.vector(raw_data[, "GYZS"])))
plot(egcm(as.vector(raw_data[, "DLNM2"]), as.vector(raw_data[, "CPI"])))
plot(egcm(as.vector(raw_data[, "DLNM2"]), as.vector(raw_data[, "SHIBOR"])))

# 对变量GYZS和其他变量进行协整检验。
plot(egcm(as.vector(raw_data[, "GYZS"]), as.vector(raw_data[, "CPI"])))
plot(egcm(as.vector(raw_data[, "GYZS"]), as.vector(raw_data[, "SHIBOR"])))

# 对变量CPI和其他变量进行协整检验。
plot(egcm(as.vector(raw_data[, "CPI"]), as.vector(raw_data[, "SHIBOR"])))

# 下面对任意两个变量之间做因果检验。
names <- c("LNSB", "DLNM2", "GYZS", "CPI", "SHIBOR")
for (f in names) {
  for (t in names) {
    if (f != t) {
      v <- VAR(raw_data[, c(f, t)])
      result <- causality(v, cause=t)
      print(result)
    }
  }
}

# 我们用自动的方法来选择最优的滞后阶数。
VARselect(raw_data, lag.max = 8, type = "both")

# 从表中的输出可以看出按照AIC和FPE标准，最优的滞后阶数是2，按照HQ和SC的标准，最优的阶数是1。不妨按照2来对每个变量做ADF测试。
lnsb.df <- summary(ur.df(as.vector(raw_data[, "LNSB"]), type="drift", lags=1))
lnsb.df

diff_lnsb.df <- summary(ur.df(as.vector(diff(raw_data[, "LNSB"])), type="drift", lags=1))
diff_lnsb.df

# summary(ur.df(as.vector(raw_data[, "DLMN2"]), type="trend", lags=2))
# summary(ur.df(as.vector(raw_data[, "GYZS"]), type="trend", lags=2))
# summary(ur.df(as.vector(raw_data[, "CPI"]), type="trend", lags=2))
# summary(ur.df(as.vector(raw_data[, "SHIBOR"]), type="trend", lags=2))



#  下面我们来估计SVAR模型中的参数。
# "LNSB"   "DLNM2"  "GYZS"   "CPI"    "SHIBOR"
colnames(raw_data)
var_raw_data = VAR(as.matrix(raw_data), p=1, type=c("both"), ic = c("AIC", "HQ", "SC", "FPE"))
print(var_raw_data)

# column major to create matrix.
A = matrix(
  c(1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    NA, NA, 1, NA, NA,
    0, NA, NA, 1, 0,
    NA, NA, NA, 0, 1
  ),
  nrow = 5,
  ncol = 5)

B = diag(5)
svar_raw_data = SVAR(var_raw_data, Amat = A, Bmat = B, estmethod="direct")
print(svar_raw_data)

# 下面对模型做预测误差的方差分解。
vd_raw_data = fevd(svar_raw_data, n.ahead = 5)
print(vd_raw_data)
# 计算脉冲响应。
# irf_raw_data = irf(svar_raw_data, n.ahead = 5)
# print(irf_raw_data)

