%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of CoCoSim.
% Copyright (C) 2018  The university of Iowa
% Author: Mudathir Mahgoub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef SFStruct
    %SFSTRUCT
    properties
    end
    
    methods(Static)
        function dataStruct = buildDataStruct(data)
            dataStruct.Id = data.id;
            dataStruct.Name = data.name;
            dataStruct.Datatype = data.DataType;
            dataStruct.CompiledType = data.CompiledType;
            dataStruct.Port = data.Port;
            dataStruct.InitialValue = data.Props.InitialValue;
            dataStruct.Scope = data.scope;
            dataStruct.ArraySize = data.Props.Array.Size;
            dataStruct.CompiledSize = data.CompiledSize;
        end
        
        
        function eventStruct = buildEventStruct(event)
            eventStruct.Id = event.id;
            eventStruct.Name = event.name;
            eventStruct.Port = event.Port;
            eventStruct.Scope = event.scope;
            eventStruct.Trigger = event.Trigger;
        end
        
        
        function stateStruct =  buildStateStruct(state)
            % set the state path
            stateStruct.Path = strcat (state.Path, '/',state.name);
            
            %set the id of the state
            stateStruct.Id = state.id;
            
            %set the ExecutionOrder of the state
            stateStruct.ExecutionOrder = state.ExecutionOrder;
            
            %set the name of the state
            stateStruct.Name = state.name;
            
            % parse the label string of the state
            %keep the original LabelString
            stateStruct.LabelString = state.LabelString;
            stateAction = edu.uiowa.chart.state.StateParser.parse(state.LabelString);
            
            % set the state actions
            stateStruct.Actions.Entry = cell(stateAction.entry);
            stateStruct.Actions.During = cell(stateAction.during);
            stateStruct.Actions.Exit = cell(stateAction.exit);
            stateStruct.Actions.Bind = cell(stateAction.bind);
            stateStruct.Actions.On = SFStruct.getOnAction(stateAction.on);
            stateStruct.Actions.OnAfter = SFStruct.getOnAction(stateAction.onAfter);
            stateStruct.Actions.OnBefore = SFStruct.getOnAction(stateAction.onBefore);
            stateStruct.Actions.OnAt = SFStruct.getOnAction(stateAction.onAt);
            stateStruct.Actions.OnEvery = SFStruct.getOnAction(stateAction.onEvery);
            
            % set the state transitions
            stateStruct.InnerTransitions = {};
            transitions = state.innerTransitions;
            for i = 1 : length(transitions)
                transitionStruct = SFStruct.buildDestinationStruct(transitions(i));
                stateStruct.InnerTransitions = [stateStruct.InnerTransitions transitionStruct];
            end
            
            stateStruct.OuterTransitions = {};
            transitions = state.outerTransitions;
            for i = 1 : length(transitions)
                transitionStruct = SFStruct.buildDestinationStruct(transitions(i));
                stateStruct.OuterTransitions = [stateStruct.OuterTransitions transitionStruct];
            end
            
            %ToDo: find a better name for composition
            stateStruct.Composition = SFStruct.getContent(state, true);
        end
        
        function content = getContent(chartObject, self)
            content = {};
            
            % specify the decomposition
            if isprop(chartObject, 'Decomposition')
                content.Type = chartObject.Decomposition;
            else
                content.Type = 'EXCLUSIVE_OR';
            end
            
            %handle initial transitions
            content.DefaultTransitions = {};
            try
                defaultTransitions = chartObject.defaultTransitions;
                for i = 1 : length(defaultTransitions)
                    transitionStruct = SFStruct.buildDestinationStruct(defaultTransitions(i));
                    content.DefaultTransitions = ...
                        [content.DefaultTransitions transitionStruct];
                end
            catch
                % continue, case of Stateflow.TruthTableChart
            end
            %handle initial states
            childStates = chartObject.find('-isa', 'Stateflow.State', '-depth', 1);
            
            index = 0;
            % for states: child states start from childstates(2)
            % for chart: child states  start from childStates(1)
            if self
                index = 1;
            end
            
            content.Substates = cell(length(childStates) - index,1);
            content.States = cell(length(childStates) - index,1);
            for i = 1 + index : length(childStates)
                content.Substates{i-index} = childStates(i).name;
                content.States{i-index} = childStates(i).id;
            end
            % add subJunctions
            junctions = chartObject.find('-isa','Stateflow.Junction', '-depth',1);
            content.SubJunctions = cell(length(junctions), 1);
            for i = 1 : length(junctions)
                jun.Name = SFStruct.junctionName(junctions(i));
                jun.Type = junctions(i).Type;
                content.SubJunctions{i} = jun;
            end
        end
        
        function junctionStruct =  buildJunctionStruct(junction)
            % set the junction path
            junctionStruct.Path = strcat (junction.Path, '/', SFStruct.junctionName(junction));
            
            % set the junction name
            junctionStruct.Name = SFStruct.junctionName(junction);
            
            %set the id of the junction
            junctionStruct.Id = junction.id;
            
            %set the junction type
            junctionStruct.Type = junction.Type;
            
            % set the junction transitions
            junctionStruct.OuterTransitions = {};
            transitions = junction.sourcedTransitions;
            for i = 1 : length(transitions)
                transitionStruct = SFStruct.buildDestinationStruct(transitions(i));
                junctionStruct.OuterTransitions = [junctionStruct.OuterTransitions transitionStruct];
            end
        end
        
        function Name = junctionName(junction)
            Name = strcat ('Junction',int2str(junction.id));
        end
        
        function transitionStruct = buildDestinationStruct(transition)
            transitionStruct = {};
            transitionStruct.Id = transition.id;
            transitionStruct.ExecutionOrder = transition.ExecutionOrder;
            destination =  transition.Destination;
            transitionStruct.Destination.Id = destination.id;
            
            % parse the label string of the transition
            transitionObject = edu.uiowa.chart.transition.TransitionParser.parse(transition.LabelString);
            transitionStruct.Event = char(transitionObject.eventOrMessage);
            transitionStruct.Condition = char(transitionObject.condition);
            transitionStruct.ConditionAction = cell(transitionObject.conditionAction);
            transitionStruct.TransitionAction = cell(transitionObject.transitionAction);
            %keep LabelString in case the parser failed.
            transitionStruct.LabelString = transition.LabelString;
            
            % check if the destination is a state or a junction
            if strcmp(destination.Type, 'CONNECTIVE') || ...
                    strcmp(destination.Type, 'HISTORY')
                transitionStruct.Destination.Type = 'Junction';
                transitionStruct.Destination.Name = strcat(destination.Path, '/', ...
                    SFStruct.junctionName(destination));
            else
                transitionStruct.Destination.Type = 'State';
                transitionStruct.Destination.Name = strcat(destination.Path, '/', ...
                    destination.name);
            end
        end
        
        function functionStruct =  buildGraphicalFunctionStruct(functionObject)
            % set the function path
            functionStruct.Path = strcat (functionObject.Path, '/',functionObject.name);
            
            %set the id of the function
            functionStruct.Id = functionObject.id;
            
            %set the name of the function
            functionStruct.Name = functionObject.name;
            
            
            %get the junctions in the SFun
            functiontions = functionObject.find('-isa','Stateflow.Junction');
            % build the json struct for junctions
            functionStruct.Junctions = cell(length(functiontions),1);
            for index = 1 : length(functiontions)
                functionStruct.Junctions{index} = SFStruct.buildJunctionStruct(functiontions(index));
            end
            
            %set the signature of the function
            functionStruct.LabelString = functionObject.LabelString;
            % set the content of the function
            functionStruct.Composition = SFStruct.getContent(functionObject, false);
            
            % get the data of the function
            functionData = functionObject.find('-isa','Stateflow.Data');
            % build the json struct for data
            functionStruct.Data = cell(length(functionData),1);
            for index = 1 : length(functionData)
                functionStruct.Data{index} = SFStruct.buildDataStruct(functionData(index));
            end
            % get the events of the chart
            functionEvents = functionObject.find('-isa','Stateflow.Event');
            % build the json struct for events
            functionStruct.Events = cell(length(functionEvents),1);
            for index = 1 : length(functionEvents)
                functionStruct.Events{index} = SFStruct.buildEventStruct(functionEvents(index));
            end
        end
        
        
        function functionStruct =  buildSimulinkFunctionStruct(simulinkFunction)
            % set the function path
            functionStruct.Path = strcat (simulinkFunction.Path, '/',simulinkFunction.name);
            
            %set the id of the function
            functionStruct.Id = simulinkFunction.id;
            
            %set the name of the function
            functionStruct.Name = simulinkFunction.name;
            
            %set the signature of the function
            functionStruct.LabelString = simulinkFunction.LabelString;
            % set the content of the function
            functionStruct.Content = subsystems_struct(functionStruct.Path);
            
            % get the data of the function
            functionData = simulinkFunction.find('-isa','Stateflow.Data');
            % build the json struct for data
            functionStruct.Data = cell(length(functionData),1);
            for index = 1 : length(functionData)
                functionStruct.Data{index} = SFStruct.buildDataStruct(functionData(index));
            end
        end
        
        
        function truthTableStruct =  buildTruthTableStruct(truthTable)
            % set the truthTable path
            truthTableStruct.Path = strcat (truthTable.Path, '/',truthTable.name);
            
            %set the id of the truthTable
            truthTableStruct.Id = truthTable.id;
            
            %set the name of the truthTable
            truthTableStruct.Name = truthTable.name;
            
            %set the signature of the truthTable
            truthTableStruct.LabelString = truthTable.LabelString;
            
            % set the decisions of the truth table
            [conditionRows, conditionColumns] = size(truthTable.ConditionTable);
            % exclude the description and condition columns
            truthTableStruct.Decisions = cell(conditionColumns - 2,1);
            
            % pattern to extract the label from conditions and actions
            labelPattern = '^[a-zA-Z][a-zA-Z0-9_]*:';
            
            % set the actions of the truth table
            [actionRows, ~] = size(truthTable.ActionTable);
            truthTableStruct.Actions = cell(actionRows,1);
            
            % map to store action labels and indices
            actionLabelsMap = containers.Map;
            for i = 1 : actionRows
                actionLabel = regexp(truthTable.ActionTable{i,2}, labelPattern, 'match');
                if isempty(actionLabel)
                    truthTableStruct.Actions{i}.Action = truthTable.ActionTable{i,2};
                    truthTableStruct.Actions{i}.Label = '';
                else
                    action = truthTable.ActionTable{i,2};
                    actionLabel = char(actionLabel);
                    truthTableStruct.Actions{i}.Action = strrep(action, actionLabel, '');
                    actionLabel = strrep(actionLabel, ':', '');
                    truthTableStruct.Actions{i}.Label = actionLabel;
                    actionLabelsMap(actionLabel) = i;
                end
                truthTableStruct.Actions{i}.Index = i;
            end
            
            for j = 3 : conditionColumns
                truthTableStruct.Decisions{j-2}.Conditions = cell(conditionRows - 1,1);
                for i = 1 : conditionRows - 1
                    conditionLabel = regexp(truthTable.ConditionTable{i,2}, labelPattern, 'match');
                    if isempty(conditionLabel)
                        truthTableStruct.Decisions{j-2}.Conditions{i}.Condition = truthTable.ConditionTable{i,2};
                        truthTableStruct.Decisions{j-2}.Conditions{i}.Label = '';
                    else
                        conditionLabel = char(conditionLabel);
                        condition = truthTable.ConditionTable{i,2};
                        truthTableStruct.Decisions{j-2}.Conditions{i}.Condition = strrep(condition, conditionLabel, '');
                        conditionLabel = strrep(conditionLabel, ':', '');
                        truthTableStruct.Decisions{j-2}.Conditions{i}.Label = conditionLabel;
                    end
                    truthTableStruct.Decisions{j-2}.Conditions{i}.ConditionValue = truthTable.ConditionTable{i,j};
                end
                
                % decision actions
                actionsString = truthTable.ConditionTable{conditionRows,j};
                actions = strsplit(actionsString,'[,;\s]+', 'DelimiterType','RegularExpression');
                for actionIndex = 1 : length(actions)
                    actionString = char(actions(actionIndex));
                    if isKey(actionLabelsMap, actionString)
                        truthTableStruct.Decisions{j-2}.Actions{actionIndex} = actionLabelsMap(actionString);
                    else
                        truthTableStruct.Decisions{j-2}.Actions{actionIndex} = str2num(actionString);
                    end
                end
            end
            
            
            
            % get the data of the truthTable
            truthTableData = truthTable.find('-isa','Stateflow.Data');
            % build the json struct for data
            truthTableStruct.Data = cell(length(truthTableData),1);
            for index = 1 : length(truthTableData)
                truthTableStruct.Data{index} = SFStruct.buildDataStruct(truthTableData(index));
            end
            
        end
        
        function [onActionStruct] = getOnAction(onActionObject)
            onActionArray = cell(onActionObject);
            onActionStruct = cell(length(onActionArray), 1);
            for i = 1 : length(onActionStruct)
                onActionStruct{i}.N = onActionArray{i}.n;
                onActionStruct{i}.EventName = cell(onActionArray{i}.eventName);
                onActionStruct{i}.Actions = cell(onActionArray{i}.actions);
            end
        end
        
    end
end
