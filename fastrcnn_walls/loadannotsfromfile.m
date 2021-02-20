function annotations = loadannotsfromfile(filepath)
    file = fopen(filepath,'r');
    contents = textscan(file,'%s','delimiter','\n');
    contents = contents{1};
    fclose(file);
    if isempty(contents)
        annotations = 0;
        return
    end
    annotations = cell(length(contents),5);
    for i = 1:length(contents)
        temp = strsplit(contents{i},'\t');
        if isempty(temp{2})
            continue
        end
        switch temp{1}
            case 'walls'
                annotations{i,1} = 1;
            case 'floor'
                annotations{i,1} = 2;
            case 'ceiling' 
                annotations{i,1} = 3;
            case 'bed'
                annotations{i,1} = 4;
            case 'couch' 
                annotations{i,1} = 5;
            case 'chair'
                annotations{i,1} = 6;
            case 'table' 
                annotations{i,1} = 7;
            case 'drawer'
                annotations{i,1} = 8;
            case 'door' 
                annotations{i,1} = 9;
        end   
        temp = strsplit(temp{2},' ');
        if length(temp)~=4
            for j = 1:4
                annotations{i,j+1} = 0;
            end
            continue
        end
        for j = 1:4
            annotations{i,j+1} = round(str2double(temp{j}));
        end
    end
    annotations = cell2mat(annotations);
    annotations(:,3) = annotations(:,3)-annotations(:,5);
    i = 1;
    while i <= size(annotations,1)
        if all(annotations(i,2:5)==[0,0,0,0])
            annotations(i,:) = [];
            i = 0;
        elseif sum(annotations(i,2:5)==[0,0,1600,900])>2
            annotations(i,:) = [];
            i = 0;
        end
        i = i+1;
    end  
    annotations(annotations(:,2)>1580,2)=1580;
    annotations(annotations(:,2)<20,2)=20;
    annotations(annotations(:,3)<20,3)=20;
    annotations(annotations(:,3)>880,3)=880;
    for i = 1:size(annotations,1)
        if annotations(i,2)+annotations(i,4)>1590
            annotations(i,4) = 1590-annotations(i,2)-1;
        end
        if annotations(i,2)<0
            annotations(i,2) = 0;
        end
        if annotations(i,3)+annotations(i,5)>890
            annotations(i,5) = 890 - annotations(i,3)-1;
        end
        if annotations(i,3)<0
            annotations(i,3)=0;
        end
    end
end