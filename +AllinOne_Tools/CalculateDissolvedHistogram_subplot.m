function CalculateDissolvedHistogram_subplot(Data,Edges,Thresholds,CMap,HealthyEdges,HealthyFit)
%make figure
%HistFigure = figure('Name','Histogram');set(HistFigure,'WindowState','minimized');
%set(HistFigure,'color','white','Units','inches','Position',[0.25 0.25 4 4]) %Change this to be shorter
hold on

%calculate histogram
histogram(Data,Edges,'Normalization','probability','EdgeColor',[0.1 0.1 0.1],'FaceColor',[1 1 1],'FaceAlpha',0.25);

%plot healthy fit if passed
if(exist('HealthyEdges','var') && exist('HealthyFit','var'))
    plot(HealthyEdges,abs(HealthyFit)/size(Edges,2)*size(HealthyEdges,2),'k--');%healthy fit
end

%add bins to background
ylims = ylim;
xlims = xlim;
pat = patch([xlims(1) xlims(1) Thresholds(1) Thresholds(1)],[0 ylims(2) ylims(2) 0],CMap(1,:),'HandleVisibility','off');
pat.LineStyle = 'none';
pat.FaceVertexAlphaData = 0.1;
pat.FaceAlpha = 'flat';
uistack(pat,'bottom');
for bin = 2:length(Thresholds)
    pat = patch([Thresholds(bin-1) Thresholds(bin-1) Thresholds(bin) Thresholds(bin)],[0 ylims(2) ylims(2) 0],CMap(bin,:),'HandleVisibility','off');
    pat.LineStyle = 'none';
    pat.FaceVertexAlphaData = 0.1;
    pat.FaceAlpha = 'flat';
    uistack(pat,'bottom');
end
pat = patch([Thresholds(end) Thresholds(end) xlims(2) xlims(2)],[0 ylims(2) ylims(2) 0],CMap(end,:),'HandleVisibility','off');
pat.LineStyle = 'none';
pat.FaceVertexAlphaData = 0.1;
pat.FaceAlpha = 'flat';
uistack(pat,'bottom');
set(gca,'FontSize',14);

%adjust axis
axis([Edges(2) Edges(end-1) -inf inf])
hold off
%InSet = get(gca, 'TightInset');
%set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)+.01])

end