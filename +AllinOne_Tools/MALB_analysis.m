function defectArray = MALB_analysis(Image,Mask)

defect60 = medfilt3(double((Image<(mean(Image(Mask>0))*0.6)).*(Mask>0)));
defect15 = medfilt3(double((Image<(mean(Image(Mask>0))*0.15)).*(Mask>0)));
defect250 = medfilt3(double((Image>(mean(Image(Mask>0))*2)).*(Mask>0)));
defectArray = defect60+defect15+3*defect250;