png(filename="myplot.png", width=1440, height=900)
ggplot(aes(x=value, group=am, colour=factor(am)), data=mtcarsmelt) + geom_density() + facet_wrap(~variable, scales="free")
dev.off()